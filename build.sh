rgbasm -L -o hello-world.o hello-world.asm
rgblink -o hello-world.gb hello-world.o
rgblink -n hello-world.sym hello-world.o
rgbfix -v -p 0xFF hello-world.gb