    .equ BUF_CAP, 512

    .data
    .globl snake
snake:
    .space BUF_CAP                  # Writable buffer for the snake body

snake_x:    .long 0                 # The snake's current X position
snake_y:    .long 0                 # The snake's current Y position
vel_x:      .long 1                 # Velocity in X direction (1:Right, -1:Left)
vel_y:      .long 0                 # Velocity in Y direction (1:Down, -1:Up)


    .globl __progname
__progname: .quad 0
    .globl environ
environ:    .quad 0


    .text
    # These are global integer variables provided by the ncurses library.
    .extern COLS
    .extern LINES
    # We also need to tell the linker about some ncurses and standard C functions.
    .extern clear                   # Function to clear the terminal screen
    .extern usleep                  # Function for microsecond delays

    .globl start_game
start_game:
    push    %rbp
    mov     %rsp, %rbp
    sub     $16, %rsp               # Allocate 16B on stack & keep 16B alignment

    mov     %edi, -4(%rbp)

    call    board_init

    mov     -4(%rbp), %ecx

    mov     $BUF_CAP-1, %eax
    cmp     %eax, %ecx
    cmova   %eax, %ecx

    lea     snake(%rip), %rdi
    mov     $'0', %al
    cld
    rep stosb
    movb    $0, (%rdi)

    # --- Initialization ---
    # Calculate the starting position and store it in our variables.
    call    get_center_y
    mov     %eax, snake_y(%rip)     # Store initial Y coordinate

    call    get_center_x
    mov     -4(%rbp), %edx          # Restore snake length
    shr     $1, %edx                # Halve it
    sub     %edx, %eax              # start_x = center_x - len/2
    mov     %eax, snake_x(%rip)     # Store initial X coordinate

    # Initialization is done, jump into the main game loop.
    jmp     game_loop

game_loop:
    # --- 1. Handle Input ---
    call    board_get_key           # Get key press, result is in %eax
    cmp     $-1, %eax               # -1 means no key was pressed
    je      .update_pos             # If no key, skip input logic

    # Check for UP arrow (259)
    cmp     $259, %eax
    jne     .check_down
    movl    vel_y(%rip), %ecx       # Check current y velocity
    cmp     $1, %ecx                # Are we currently moving down?
    je      .update_pos             # If so, ignore the input (can't reverse)
    movl    $0, vel_x(%rip)         # Set velocity to (0, -1) for UP
    movl    $-1, vel_y(%rip)
    jmp     .update_pos

.check_down:
    # Check for DOWN arrow (258)
    cmp     $258, %eax
    jne     .check_left
    movl    vel_y(%rip), %ecx       # Check current y velocity
    cmp     $-1, %ecx               # Are we currently moving up?
    je      .update_pos             # If so, ignore the input
    movl    $0, vel_x(%rip)         # Set velocity to (0, 1) for DOWN
    movl    $1, vel_y(%rip)
    jmp     .update_pos

.check_left:
    # Check for LEFT arrow (260)
    cmp     $260, %eax
    jne     .check_right
    movl    vel_x(%rip), %ecx       # Check current x velocity
    cmp     $1, %ecx                # Are we currently moving right?
    je      .update_pos             # If so, ignore the input
    movl    $-1, vel_x(%rip)        # Set velocity to (-1, 0) for LEFT
    movl    $0, vel_y(%rip)
    jmp     .update_pos

.check_right:
    # Check for RIGHT arrow (261)
    cmp     $261, %eax
    jne     .update_pos             # Not an arrow key, ignore it
    movl    vel_x(%rip), %ecx       # Check current x velocity
    cmp     $-1, %ecx               # Are we currently moving left?
    je      .update_pos             # If so, ignore the input
    movl    $1, vel_x(%rip)         # Set velocity to (1, 0) for RIGHT
    movl    $0, vel_y(%rip)
    # Fall through to the update logic

.update_pos:
    # --- 2. Update Snake Position ---
    # new_pos = old_pos + velocity
    mov     vel_x(%rip), %eax
    add     %eax, snake_x(%rip)
    mov     vel_y(%rip), %eax
    add     %eax, snake_y(%rip)

    # --- 3. Draw Everything ---
    call    clear                   # Clear the entire screen
    mov     snake_x(%rip), %edi     # 1st arg for board_put_str: x
    mov     snake_y(%rip), %esi     # 2nd arg for board_put_str: y
    lea     snake(%rip), %rdx       # 3rd arg: the snake string
    call    board_put_str           # Draw the snake (this also refreshes screen)

    # --- 4. Delay to control speed ---
    mov     $100000, %edi           # 100,000 microseconds = 100ms = 0.1s
    call    usleep

    # --- 5. Repeat ---
    jmp     game_loop
    # The program will now loop here indefinitely.

# The old exit logic is no longer reachable.
# A proper exit would be handled by a key press (e.g. 'q').
    leave
    ret

# --- Helper Assembly Functions (Unchanged) ---
get_center_y:
    mov     LINES(%rip), %eax
    shr     $1, %eax
    ret

get_center_x:
    mov     COLS(%rip), %eax
    shr     $1, %eax
    ret

