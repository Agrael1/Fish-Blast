module;
#include <godot_cpp/godot.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/button.hpp>
#include <godot_cpp/classes/scene_tree.hpp>

export module fb.main_menu;

export namespace fb {
class MainMenu : public godot::Node2D
{
    GDCLASS(MainMenu, godot::Node2D);

public:
    void _ready() override{
        godot::UtilityFunctions::print("Hello, World!");

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
} // namespace fb