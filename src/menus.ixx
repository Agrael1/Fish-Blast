module;
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/control.hpp>
#include <godot_cpp/classes/input.hpp>
#include <godot_cpp/classes/input_map.hpp>
#include <godot_cpp/classes/animation_player.hpp>
export module fb.main_menu;

export namespace fb {
class MainMenu : public godot::Node2D
{
    GDCLASS(MainMenu, godot::Node2D);

public:
    void _ready() override
    {

        // Get button nodes
        auto play_button = get_node<godot::Button>("PanelContainer/MarginContainer/VBoxContainer/Play");
        auto quit_button = get_node<godot::Button>("PanelContainer/MarginContainer/VBoxContainer/Quit");

        // Connect button signals
        if (play_button && quit_button) {
            play_button->connect("pressed", callable_mp(this, &MainMenu::_on_PlayButton_pressed));
            quit_button->connect("pressed", callable_mp(this, &MainMenu::_on_QuitButton_pressed));
        }
    }
    static void _bind_methods()
    {
    }

    void _on_PlayButton_pressed()
    {
        get_tree()->change_scene_to_file("res://proto/proto.tscn");
    }

    void _on_QuitButton_pressed()
    {
        get_tree()->quit();
    }

public:
};

class PauseMenu : public godot::Control
{
    GDCLASS(PauseMenu, godot::Control);

public:
    void _ready() override
    {
        godot::InputMap::get_singleton()->load_from_project_settings();
        auto resume_button = get_node<godot::Button>("PanelContainer/MarginContainer/VBoxContainer/Resume");
        auto restart_button = get_node<godot::Button>("PanelContainer/MarginContainer/VBoxContainer/Restart");
        auto quit_button = get_node<godot::Button>("PanelContainer/MarginContainer/VBoxContainer/Quit");
        if (resume_button && quit_button) {
            resume_button->connect("pressed", callable_mp(this, &PauseMenu::on_resume_button_pressed));
            restart_button->connect("pressed", callable_mp(this, &PauseMenu::on_restart_button_pressed));
            quit_button->connect("pressed", callable_mp(this, &PauseMenu::on_quit_button_pressed));
        }
        animation_player = get_node<godot::AnimationPlayer>("AnimationPlayer");
        if (animation_player) {
            animation_player->play("RESET");
        }
    }
    static void _bind_methods()
    {
    }

    void _process(float delta)
    {
        test_escape();
    }

public:
    void resume()
    {
        get_tree()->set_pause(false);
        animation_player->play_backwards("blur");
        queue_free();
    }

    void pause()
    {
        get_tree()->set_pause(true);
        animation_player->play("blur");
    }

    void test_escape()
    {
        auto& input = *godot::Input::get_singleton();
        if (input.is_action_just_pressed("esc")) {
            get_tree()->is_paused() ? resume() : pause();
        }
    }

    void on_resume_button_pressed()
    {
        resume();
    }

    void on_quit_button_pressed()
    {
        get_tree()->change_scene_to_file("res://proto/menu.tscn");
    }

    void on_restart_button_pressed()
    {
        resume();
        get_tree()->reload_current_scene();
    }

private:
    godot::AnimationPlayer* animation_player;
};
} // namespace fb