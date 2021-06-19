import Foundation
import ValorantAPI

extension AssetClient {
	func getGameModeInfo() async throws -> [GameModeInfo] {
		try await send(GameModeInfoRequest())
	}
}

private struct GameModeInfoRequest: AssetRequest {
	let path = "/v1/gamemodes"
	
	typealias Response = [GameModeInfo]
}

struct GameModeInfo: AssetItem, Codable, Identifiable {
	private var uuid: ID
	var id: ObjectID<Self, UUID> { uuid }
	var displayName: String
	var duration: String?
	var allowsMatchTimeouts: Bool
	var isTeamVoiceAllowed: Bool
	var isMinimapHidden: Bool
	/// Always seems to be 1.
	var orbCount: Int
	var teamRoles: [String]?
	var gameFeatureOverrides: [GameFeatureToggle.Override]?
	var gameRuleBoolOverrides: [GameRuleBool.Override]?
	var displayIcon: AssetImage?
	var assetPath: String
	
	/// Of course they don't do what would make sense and use the UUID; instead we need to figure out the commonalities between the asset path and the client API game mode ID (which is also trimmed down)
	func gameID() -> GameMode.ID {
		// e.g. "ShooterGame/Content/GameModes/Bomb/BombGameMode_PrimaryAsset"
		
		let pathPrefix = "ShooterGame/Content/"
		assert(assetPath.hasPrefix(pathPrefix))
		let trimmed = assetPath.dropFirst(pathPrefix.count)
		// e.g. "GameModes/Bomb/BombGameMode_PrimaryAsset"
		
		let pathSuffix = "_PrimaryAsset"
		assert(trimmed.hasSuffix(pathSuffix))
		return .init(String(trimmed.dropLast(pathSuffix.count)))
		// e.g. "GameModes/Bomb/BombGameMode"
	}
	
	func gameFeatureOverride(for name: GameFeatureToggle.Name) -> Bool? {
		gameFeatureOverrides?.first { $0.featureName == name }?.state
	}
	
	func gameRuleOverride(for name: GameRuleBool.Name) -> Bool? {
		gameRuleBoolOverrides?.first { $0.ruleName == name }?.state
	}
	
	var images: [AssetImage] {
		displayIcon
	}
	
	struct TeamRole: NamespacedID {
		static let freeForAll = Self("FreeForAll")
		
		static let namespace = "EAresTeamRole"
		var rawValue: String
	}
}

enum GameFeatureToggle {
	struct Name: NamespacedID {
		static let reuseActorOnRespawn = Self("ReuseActorOnRespawn")
		static let gunshotsInFogOfWar = Self("GunshotsInFogOfWar")
		static let allowShoppingWhileDead = Self("AllowShoppingWhileDead")
		static let warmupSlowdownTransition = Self("WarmupSlowdownTransition")
		static let encourageFarDeathmatchSpawning = Self("DeathmatchEncourageFarSpawning")
		
		static let namespace = "EGameFeatureToggleName"
		var rawValue: String
	}
	
	struct Override: Codable {
		var featureName: Name
		var state: Bool
	}
}

enum GameRuleBool {
	struct Name: NamespacedID {
		static let majorityVoteAgents = Self("MajorityVoteAgents")
		static let isOvertimeWinByTwo = Self("IsOvertimeWinByTwo")
		
		static let namespace = "EGameRuleBoolName"
		var rawValue: String
	}
	
	struct Override: Codable {
		var ruleName: Name
		var state: Bool
	}
}
