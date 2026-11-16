import GraniteAgents

/// The graph agent's place in Granite's roster: an app that links this package finds the `graph` agent by this
/// record, with nothing listed by hand.
@used @section("__DATA_CONST,__granite")
let graphRecord: GraniteRoster.Record = { GraniteRoster.record(GraphAgent.self) }
