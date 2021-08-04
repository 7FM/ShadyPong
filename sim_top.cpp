//**************************************************************************
//
//    Copyright (C) 2020  John Winans
//
//    This library is free software; you can redistribute it and/or
//    modify it under the terms of the GNU Lesser General Public
//    License as published by the Free Software Foundation; either
//    version 2.1 of the License, or (at your option) any later version.
//
//    This library is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
//    Lesser General Public License for more details.
//
//    You should have received a copy of the GNU Lesser General Public
//    License along with this library; if not, write to the Free Software
//    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301
//    USA
//
//**************************************************************************

#include <getopt.h>
#include <unistd.h>

#include <chrono>
#include <cmath>
#include <csignal>
#include <cstdlib>
#include <ctype.h>
#include <exception>
#include <fstream>
#include <functional>
#include <iomanip>
#include <iostream> // Need std::cout
#include <string>
#include <thread>
#include <verilated.h> // Defines common routines
#include <verilated_vcd_c.h>

#include "Vsim_top.h"       // basic Top header
#include "Vsim_top__Syms.h" // all headers to access exposed internal signals

#include "sim_src/keyboard_control.hpp"
#include "sim_src/window.hpp"

//#define VGA_640_350_70_Hz
//#define VGA_640_350_85_Hz
//#define VGA_640_400_70_Hz
//#define VGA_640_400_85_Hz
//#define VGA_640_480_60_Hz
//#define VGA_640_480_73_Hz
#define VGA_640_480_75_Hz
//#define VGA_640_480_85_Hz
//#define VGA_640_480_100_Hz
//#define VGA_720_400_85_Hz
//#define VGA_768_576_60_Hz
//#define VGA_768_576_72_Hz
//#define VGA_768_576_75_Hz
//#define VGA_800_600_56_Hz
//#define VGA_800_600_60_Hz
//#define VGA_1024_768_43_Hz_INTERLACED
#include "sim_src/vga_timing.hpp"

static Vsim_top *ptop; // Instantiation of module

static vluint64_t main_time = 0; // Current simulation time
static VerilatedVcdC *tfp = 0;

#ifndef PERIOD
#define PERIOD 5
#endif

#ifndef WINDOW_WIDTH
#define WINDOW_WIDTH 1280
#endif
#ifndef WINDOW_HEIGHT
#define WINDOW_HEIGHT 720
#endif

#define VGA_WIDTH (WIDTH + HSYNC_FPORCH + HSYNC_PULSE + HSYNC_BPORCH)
#define VGA_HEIGHT (HEIGHT + VSYNC_FPORCH + VSYNC_PULSE + VSYNC_BPORCH)

#ifndef BALL_PIXSIZE
#define BALL_PIXSIZE 5
#endif
#ifndef PLAYER_LEN
#define PLAYER_LEN 50
#endif
#ifndef PLAYER_WID
#define PLAYER_WID 8
#endif
#ifndef PLAYER_MOVE_SPEED
#define PLAYER_MOVE_SPEED 4
#endif
#ifndef BALL_MOVE_SPEED
#define BALL_MOVE_SPEED 4
#endif

static void sanityChecks();

/**
* Called by $time in Verilog
****************************************************************************/
double sc_time_stamp() {
    return main_time; // converts to double, to match
                      // what SystemC does
}

/******************************************************************************/
static void tick(int count, bool dump) {
    do {
        //if (tfp)
        //tfp->dump(main_time); // dump traces (inputs stable before outputs change)
        ptop->eval(); // Evaluate model
        main_time++;  // Time passes...
        if (tfp && dump)
            tfp->dump(main_time); // inputs and outputs all updated at same time
    } while (--count);
}

/******************************************************************************/

static void run(uint64_t limit, bool dump = true) {
    do {
        ptop->CLK = 1;
        tick(PERIOD, dump);
        ptop->CLK = 0;
        tick(PERIOD, dump);
        sanityChecks();
    } while (--limit);
}

/******************************************************************************/
static void reset() {
    // this module has nothing to reset
    ptop->btns = 0xF;
}

/******************************************************************************/

namespace pong::game_engine {
    typedef enum {
        IDLE = 0,
        COLLISION_CHECK_START,
        COLLISION_CHECK_1,
        COLLISION_CHECK_2,
        COLLISION_CHECK_3,
        COLLISION_CHECK_4,
        COLLISION_CHECK_5,
        COLLISION_CHECK_6,
        COLLISION_CHECK_7,
        COLLISION_CHECK_8,
        COLLISION_CHECK_END,
        CALC_NEXT_POS_BALL_X,
        CALC_NEXT_POS_PLAYER_1,
        CALC_NEXT_POS_BALL_Y,
        CALC_NEXT_POS_PLAYER_2,
        NORMAL_END,
        SCORE_END
    } FSMStates;

    typedef struct {
        bool tmpPosCmpReg1;
        bool tmpPosCmpReg2;
        bool tmpPosCmpReg3;
        bool tmpPosCmpReg4;
        uint32_t tmpPosVarReg1;
        uint32_t tmpPosVarReg2;
        FSMStates fsmState;

        bool ballMovesPosX;
        bool ballMovesPosY;
        uint32_t player1Pos;
        uint32_t player2Pos;
        uint32_t ballXPos;
        uint32_t ballYPos;
    } GameEngineState;

    static const GameEngineState &getGameEngineState() {

        static GameEngineState state;

        uint32_t oneHotFSMState = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_fsmState();
        // Ensure its a power of 2: uses one hot encoding!
        assert(!(oneHotFSMState & (oneHotFSMState - 1)));
        state.fsmState = static_cast<FSMStates>(static_cast<uint32_t>(std::log2(oneHotFSMState)));
        state.tmpPosCmpReg1 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosCmpReg1();
        state.tmpPosCmpReg2 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosCmpReg2();
        state.tmpPosCmpReg3 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosCmpReg3();
        state.tmpPosCmpReg4 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosCmpReg4();
        state.tmpPosVarReg1 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosVarReg1();
        state.tmpPosVarReg2 = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_tmpPosVarReg2();
        state.ballMovesPosX = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_ballMovesPosX();
        state.ballMovesPosY = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_ballMovesPosY();
        state.player1Pos = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_player1Pos();
        state.player2Pos = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_player2Pos();
        state.ballXPos = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_ballXPos();
        state.ballYPos = ptop->sim_top->uut->pixelCreator->gameEngine->get_game_engine_ballYPos();

        return state;
    }
}; // namespace pong::game_engine

static void sanityChecks() {
    const pong::game_engine::GameEngineState &gameEngineState = pong::game_engine::getGameEngineState();

    switch (gameEngineState.fsmState) {
        case pong::game_engine::IDLE:

            break;
        case pong::game_engine::COLLISION_CHECK_START:

            break;
        case pong::game_engine::COLLISION_CHECK_1:
            assert(gameEngineState.tmpPosVarReg1 == (gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballXPos > PLAYER_WID));
            break;
        case pong::game_engine::COLLISION_CHECK_2:
            assert(gameEngineState.tmpPosVarReg1 == (gameEngineState.player1Pos + PLAYER_LEN));
            assert(gameEngineState.tmpPosVarReg2 == (gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.ballXPos > PLAYER_WID));
            break;
        case pong::game_engine::COLLISION_CHECK_3:
            assert(gameEngineState.tmpPosVarReg1 == (gameEngineState.player2Pos + PLAYER_LEN));
            assert(gameEngineState.tmpPosVarReg2 == (gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballYPos < gameEngineState.player1Pos + PLAYER_LEN));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos <= PLAYER_WID));
            break;
        case pong::game_engine::COLLISION_CHECK_4:
            assert(gameEngineState.tmpPosVarReg2 == (gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballYPos < gameEngineState.player2Pos + PLAYER_LEN));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID));
            assert(gameEngineState.tmpPosCmpReg4 == (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE));
            break;
        case pong::game_engine::COLLISION_CHECK_5:
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.player2Pos < gameEngineState.ballYPos + BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.player2Pos + PLAYER_LEN > gameEngineState.ballYPos));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID));
            assert(gameEngineState.tmpPosCmpReg4 == (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos));
            break;
        case pong::game_engine::COLLISION_CHECK_6:
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballXPos < WIDTH - BALL_PIXSIZE - PLAYER_WID));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.player2Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player2Pos + PLAYER_LEN > gameEngineState.ballYPos));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID));
            assert(gameEngineState.tmpPosCmpReg4 == (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos));
            break;
        case pong::game_engine::COLLISION_CHECK_7:
            assert(((gameEngineState.tmpPosVarReg2 & 1) == 1) == (!(gameEngineState.ballXPos < WIDTH - BALL_PIXSIZE - PLAYER_WID)));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballYPos > 0));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.player2Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player2Pos + PLAYER_LEN > gameEngineState.ballYPos));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID && gameEngineState.ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)));
            assert(gameEngineState.tmpPosCmpReg4 == (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos));
            break;
        case pong::game_engine::COLLISION_CHECK_8:
            assert(((gameEngineState.tmpPosVarReg2 & 1) == 1) == (!(gameEngineState.ballXPos < WIDTH - BALL_PIXSIZE - PLAYER_WID) && (gameEngineState.player2Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player2Pos + PLAYER_LEN > gameEngineState.ballYPos)));
            assert(gameEngineState.tmpPosCmpReg1 == (gameEngineState.ballYPos < HEIGHT - BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.ballYPos > 0));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID && gameEngineState.ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)));
            assert(gameEngineState.tmpPosCmpReg4 == (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos));

            //std::cout << "ballYPos < (HEIGHT - BALL_PIXELSIZE): " << gameEngineState.tmpPosCmpReg1 << std::endl;
            //std::cout << "ballYPos > 0: " << gameEngineState.tmpPosCmpReg2 << std::endl;
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.ballYPos > 0));
            break;
        case pong::game_engine::COLLISION_CHECK_END:
            assert(((gameEngineState.tmpPosVarReg2 & 1) == 1) == ((!(gameEngineState.ballXPos < WIDTH - BALL_PIXSIZE - PLAYER_WID) && (gameEngineState.player2Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player2Pos + PLAYER_LEN > gameEngineState.ballYPos)) ||
                                                                  (gameEngineState.ballXPos <= PLAYER_WID && gameEngineState.player1Pos < gameEngineState.ballYPos + BALL_PIXSIZE && gameEngineState.player1Pos + PLAYER_LEN > gameEngineState.ballYPos)));
            assert(gameEngineState.tmpPosCmpReg2 == (gameEngineState.ballYPos > 0 && gameEngineState.ballYPos < HEIGHT - BALL_PIXSIZE));
            assert(gameEngineState.tmpPosCmpReg3 == (gameEngineState.ballXPos > PLAYER_WID && gameEngineState.ballXPos < (WIDTH - BALL_PIXSIZE - PLAYER_WID)));

            //std::cout << "ballCollidesPlayer: " << (gameEngineState.tmpPosVarReg2 & 1) << std::endl;
            //std::cout << "~ballCollidesSides: " << gameEngineState.tmpPosCmpReg3 << std::endl;
            //std::cout << "~ballCollidesBouncesBorders: " << gameEngineState.tmpPosCmpReg2 << std::endl;
            //std::cout << "ballMovesPosY: " << gameEngineState.ballMovesPosY << std::endl;
            //std::cout << "ballYPos: " << gameEngineState.ballYPos << std::endl;
            break;
        case pong::game_engine::CALC_NEXT_POS_BALL_X:

            break;
        case pong::game_engine::CALC_NEXT_POS_PLAYER_1:

            break;
        case pong::game_engine::CALC_NEXT_POS_BALL_Y:

            break;
        case pong::game_engine::CALC_NEXT_POS_PLAYER_2:

            break;
        case pong::game_engine::NORMAL_END:

            break;
        case pong::game_engine::SCORE_END:
            std::cout << "Player1Pos: " << gameEngineState.player1Pos << std::endl;
            std::cout << "Player2Pos: " << gameEngineState.player2Pos << std::endl;
            std::cout << "BallXPos: " << gameEngineState.ballXPos << std::endl;
            std::cout << "BallYPos: " << gameEngineState.ballYPos << std::endl;
            std::cout << "============== Player scored, next Round! ==============" << std::endl;
            break;
        default:
            throw std::runtime_error(std::string("Unknown game engine FSM State: ") + std::to_string(static_cast<int>(gameEngineState.fsmState)));
            break;
    }
}

static volatile bool doRun = true;

static void handleSignal(int signum) {
    if (signum == SIGINT) {
        std::cout << "exiting..." << std::endl;
        doRun = false;
    }
}

static vga_pong::lcd::Window::PixelType encodePixel(uint8_t r, uint8_t g, uint8_t b) {
    // Desired format: SDL_PIXELFORMAT_ARGB8888
    return (static_cast<vga_pong::lcd::Window::PixelType>(0x0FF) << 24) |
           (static_cast<vga_pong::lcd::Window::PixelType>((r << 4) | r) << 16) |
           (static_cast<vga_pong::lcd::Window::PixelType>((g << 4) | g) << 8) |
           static_cast<vga_pong::lcd::Window::PixelType>((b << 4) | b);
}

static void frame(vga_pong::lcd::Window::PixelType *frameBuffer) {
    for (int idx = 0; idx < VGA_WIDTH * VGA_HEIGHT; ++idx) {
        /*
            output logic vga_h_sync,
            output logic vga_v_sync,
            output logic [3:0] vga_R, 
            output logic [3:0] vga_G,
            output logic [3:0] vga_B,
        */
        run(1, false);
        frameBuffer[idx] = encodePixel(ptop->vga_R, ptop->vga_G, ptop->vga_B);
    }
}

static void handleKeyInput(bool released, SDL_Keycode key) {
    uint8_t convertedEvent = released ? 1 : 0;
    switch (key) {
        case SDLK_w:
            ptop->btns = (convertedEvent << 2) | (ptop->btns & ~(1 << 2));
            break;
        case SDLK_s:
            ptop->btns = (convertedEvent << 3) | (ptop->btns & ~(1 << 3));
            break;
        case SDLK_UP:
            ptop->btns = (convertedEvent << 0) | (ptop->btns & ~(1 << 0));
            break;
        case SDLK_DOWN:
            ptop->btns = (convertedEvent << 1) | (ptop->btns & ~(1 << 1));
            break;
    }
}

static const std::map<SDL_Keycode, std::function<void(bool, SDL_Keycode)>> keyMapping = {
    {SDLK_w, handleKeyInput},
    {SDLK_s, handleKeyInput},
    {SDLK_UP, handleKeyInput},
    {SDLK_DOWN, handleKeyInput}};

static void runVisualSimulation() {
    /* signal and window stuff */
    std::signal(SIGINT, handleSignal);

    SDL_Init(0);
    assert(SDL_InitSubSystem(SDL_INIT_EVENTS) == 0);

    vga_pong::lcd::Window windowCanvas(WINDOW_WIDTH, WINDOW_HEIGHT, VGA_WIDTH, VGA_HEIGHT);

    using frames = std::chrono::duration<int64_t, std::ratio<1, FPS>>;
    auto nextFrame = std::chrono::system_clock::now() + frames{0};
    auto lastFrame = std::chrono::system_clock::now() + frames{0};

    auto frameBuffer = windowCanvas.pixels();

    for (; doRun;) {
        SDL_Event event;

        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_QUIT || event.window.event == SDL_WINDOWEVENT_CLOSE) {
                goto breakOuterLoop;
            }
            processSDLEvent(event, keyMapping);
        }

        frame(frameBuffer);

        windowCanvas.present();

        std::this_thread::sleep_until(nextFrame);
        nextFrame += frames{1};

        auto currentTime = std::chrono::system_clock::now();
        auto dt = std::chrono::duration_cast<std::chrono::microseconds>(currentTime - lastFrame);
        std::cout << "Current FPS: " << (1000000.0 / dt.count()) << std::endl;
        lastFrame = currentTime;
    }
breakOuterLoop:

    SDL_Quit();
}

/******************************************************************************/
int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    ptop = new Vsim_top; // Create instance

    int verbose = 0;

    // Skip all visible lines except the last
    int start = 800 * 479;

    bool runGui = true;

    int opt;
    while ((opt = getopt(argc, argv, ":s:tv:")) != -1) {
        switch (opt) {
            case 'v':
                verbose = std::atoi(optarg);
                break;
            case 't':
                // init trace dump
                Verilated::traceEverOn(true);
                tfp = new VerilatedVcdC;
                ptop->trace(tfp, 99);
                tfp->open("wave.vcd");
                runGui = false;
                break;
            case 's':
                start = std::atoi(optarg);
                break;
            case ':':
                printf("option needs a value\n");
                break;
            case '?': //used for some unknown options
                printf("unknown option: %c\n", optopt);
                break;
        }
    }

    // start things going
    reset();

    if (runGui) {
        runVisualSimulation();
    } else {
        if (start) {
            run(start, false);
        }
        // Only dump transistion lines to new frame
        run(800 * (525 + 1 - 479), true);
    }

    if (tfp)
        tfp->close();

    ptop->final(); // Done simulating

    if (tfp)
        delete tfp;

    delete ptop;

    return 0;
}