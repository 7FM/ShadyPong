#include "window.hpp"

#include <iostream>

namespace vga_pong::lcd {
    Window::Window(uint32_t windowWidth, uint32_t windowHeight, uint32_t width, uint32_t height, const char *title) : width(width), height(height) {
        assert(SDL_InitSubSystem(SDL_INIT_VIDEO) == 0);
        window = SDL_CreateWindow(title, 100, 100,
                                  windowWidth, windowHeight, SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE);
        assert(window);
        renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_TARGETTEXTURE);
        assert(renderer);
        SDL_RenderSetLogicalSize(renderer, width, height);
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);
        SDL_RenderPresent(renderer);
        texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING, width, height);
        assert(texture);
        buffer = new PixelType[width * height]();
    }

    Window::~Window() {
        std::cout << "destroying window" << std::endl;
        SDL_DestroyTexture(texture);
        SDL_DestroyRenderer(renderer);
        SDL_DestroyWindow(window);
        delete[] buffer;
    }

    void Window::present() {
        SDL_UpdateTexture(texture, NULL, buffer, width * sizeof(PixelType));
        SDL_RenderCopy(renderer, texture, NULL, NULL);
        SDL_RenderPresent(renderer);
    }

    Window::PixelType *Window::pixels() {
        return buffer;
    }

    const Window::PixelType *Window::pixels() const {
        return buffer;
    }

} // namespace gbaemu::lcd
