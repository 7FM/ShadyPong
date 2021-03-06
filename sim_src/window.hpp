#ifndef WINDOW_HPP
#define WINDOW_HPP

#ifdef __clang__
/*code specific to clang compiler*/
#include <SDL2/SDL.h>
#elif __GNUC__
/*code for GNU C compiler */
#include <SDL2/SDL.h>
#elif _MSC_VER
/*usually has the version number in _MSC_VER*/
/*code specific to MSVC compiler*/
#include <SDL.h>
#elif __MINGW32__
/*code specific to mingw compilers*/
#include <SDL2/SDL.h>
#else
#error "unsupported compiler!"
#endif

#include <cassert>
#include <cstdint>

namespace vga_pong::lcd {
    class Window {
      private:
        const uint32_t width;
        const uint32_t height;

      public:
        typedef uint32_t PixelType;

      private:
        SDL_Window *window;
        SDL_Renderer *renderer;
        SDL_Texture *texture;

        PixelType *buffer;

      public:
        Window(uint32_t windowWidth, uint32_t windowHeight, uint32_t width, uint32_t height, const char *title = "VGA Pong Simulation");
        ~Window();
        void present();

        PixelType *pixels();
        const PixelType *pixels() const;
    };
} // namespace vga_pong::lcd

#endif /* WINDOW_HPP */
