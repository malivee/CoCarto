import Foundation

func biomeSidesMatch(
    _ first: WorldCellDefinition,
    toward direction: Direction,
    _ second: WorldCellDefinition
) -> Bool {
    first.biomeEdges[direction] == second.biomeEdges[direction.opposite]
}

func biomeSidesMatch(
    _ first: WorldCellDefinition,
    firstRotation: GridRotation,
    toward direction: Direction,
    _ second: WorldCellDefinition,
    secondRotation: GridRotation
) -> Bool {
    first.biomeEdges.rotated(by: firstRotation)[direction] == second.biomeEdges.rotated(by: secondRotation)[direction.opposite]
}

func biomeSidesMatch(
    _ first: ResolvedWorldCell,
    toward direction: Direction,
    _ second: ResolvedWorldCell
) -> Bool {
    first.biomeEdges[direction] == second.biomeEdges[direction.opposite]
}
