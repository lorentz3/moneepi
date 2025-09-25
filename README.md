# ChessJourney

A Flutter application for tracking and visualizing chess moves with an interactive chessboard.

## Description

ChessJourney is a mobile chess application that allows users to record, track, and visualize chess moves. The app features a unique layout with a scrollable list of moves and a large interactive chessboard that updates when moves are selected.

## Features

- **Interactive Chessboard**: Large chessboard with 10px margins that takes up most of the screen
- **Move Tracking**: Record and store chess moves with piece information, destinations, titles, and descriptions
- **Player Turn Management**: Automatic tracking of whose turn it is (White/Black)
- **Visual Move Selection**: Click on any move in the list to see it displayed on the chessboard
- **Custom Chess Pieces**: Support for custom chess piece images (currently pawns for white/black)
- **Database Storage**: SQLite database for persistent move storage
- **Responsive Design**: Adapts to different screen sizes

## App Layout

```
┌─────────────────────────┐
│     App Bar             │
│   "ChessJourney"        │
├─────────────────────────┤
│                         │
│  Header Section:        │
│  "1. White/Black to     │
│   move" [+ Add Button]  │
├─────────────────────────┤
│                         │
│  Scrollable Moves List: │
│  ┌─────────────────────┐ │
│  │ [♟️] e4  "Opening"  │ │
│  │ [♟️] d5  "Response" │ │
│  │ [♞] Nf3 "Development"│ │
│  │ ... (scrollable)    │ │
│  └─────────────────────┘ │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │                     │ │
│ │   LARGE CHESSBOARD  │ │
│ │   (10px margins)    │ │
│ │   Interactive       │ │
│ │   Updates on click  │ │
│ │                     │ │
│ └─────────────────────┘ │
└─────────────────────────┘
```

## Technical Stack

- **Framework**: Flutter
- **Database**: SQLite with sqflite
- **Chess Engine**: flutter_chess_board
- **Platform Support**: Android, iOS, Web, Desktop

## Installation

1. Clone the repository:
```bash
git clone https://gitlab.com/lorentz3/chessjourney.git
cd chessjourney
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Usage

1. **Adding Moves**: Tap the "+" button to add new chess moves
2. **Selecting Moves**: Tap any move in the list to see it displayed on the chessboard
3. **Viewing Games**: The chessboard updates in real-time as you select different moves
4. **Player Turns**: The app automatically tracks whose turn it is

## Database Schema

The app uses a SQLite database to store move information:

- **Moves Table**: Stores piece type, starting/destination positions, move metadata
- **Move DTOs**: Data transfer objects for move information
- **Service Layer**: Handles database operations and move management

## Development

### Project Structure

```
lib/
├── database/          # Database helpers and migrations
├── dto/              # Data transfer objects
├── model/            # Data models
├── pages/            # App screens
├── services/         # Business logic
├── utils/            # Utility functions
├── widgets/          # Custom widgets
└── main.dart         # App entry point
```

### Key Components

- **SquareButton**: Custom button widget with chess piece images and black borders
- **MoveService**: Handles database operations for moves
- **ChessBoardController**: Manages chessboard state and move visualization

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Project Status

Active development. Currently supports basic move tracking and chessboard visualization.

