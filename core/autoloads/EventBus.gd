extends Node

# Event Bus for global game events

signal word_completed
signal player_died(final_xp: int, time_spent: int)
signal spawn_punishment_boss
signal exit_game_requested
