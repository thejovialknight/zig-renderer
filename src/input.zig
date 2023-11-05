const sdl = @cImport(@cInclude("SDL.h"));
const Scancode = sdl.SDL_Scancode;
const Platform = @import("platform.zig").Platform;

const NUM_BUTTONS = 6;

pub const Button = struct {
    scancode: Scancode = 0,
    held: bool = false,
    just_pressed: bool = false,
    just_released: bool = false,
};

pub const Input = struct {
    camera_delta_pitch: f32 = 0,
    camera_delta_yaw: f32 = 0,

    // CONTEXT: These buttons all need to be registered in initialize_input,
    // so make sure to reflect any changes here - there.
    // Also remember to iterate NUM_BUTTONS as these are added
    cam_forward: Button = .{ .scancode = sdl.SDL_SCANCODE_W },
    cam_left: Button = .{ .scancode = sdl.SDL_SCANCODE_A },
    cam_back: Button = .{ .scancode = sdl.SDL_SCANCODE_S },
    cam_right: Button = .{ .scancode = sdl.SDL_SCANCODE_D },
    cam_raise: Button = .{ .scancode = sdl.SDL_SCANCODE_SPACE },
    cam_lower: Button = .{ .scancode = sdl.SDL_SCANCODE_LSHIFT },

    buttons: [NUM_BUTTONS]*Button = undefined,
};


pub fn init(input: *Input) void {
    // CONTEXT: These buttons all need to be defined in the Input struct,
    // so make sure to reflect any changes here - there.
    // Also remember to iterate NUM_BUTTONS as these are added
    var i: usize = 0;
    register_button(&input.cam_forward, &input.buttons, &i);
    register_button(&input.cam_left, &input.buttons, &i);
    register_button(&input.cam_back, &input.buttons, &i);
    register_button(&input.cam_right, &input.buttons, &i);
    register_button(&input.cam_raise, &input.buttons, &i);
    register_button(&input.cam_lower, &input.buttons, &i);
}

// Adds pointer to button list and iterates i
pub fn register_button(button: *Button, buttons: *[NUM_BUTTONS]*Button, i: *usize) void {
    buttons[i.*] = button;
    i.* += 1;
}

pub fn update(platform: *Platform, input: *Input) void {
    // Update camera
    input.camera_delta_pitch = platform.mouse_delta_y;
    input.camera_delta_yaw = platform.mouse_delta_x;

    // Update buttons
    for(input.buttons) |button| {
        button.just_pressed = false;
        button.just_released = false;
    }

    for(input.buttons) |button| {
        var modified: bool = false; // to prevent false positive in keyup check
        for(0..platform.num_keydowns) |i| {
            if(platform.keydowns[i] == button.scancode) {
                if(!button.held) button.just_pressed = true;
                button.held = true;
                modified = true;
            }
        }
        for(0..platform.num_keyups) |i| {
            if(platform.keyups[i] == button.scancode) {
                if(!modified and button.held) button.just_released = true;
                button.held = false;
            }
        }
    }
}
