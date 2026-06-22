enum Phase { idle, intro, independent, discussion, voting, synthesis, complete }

Phase phaseFromString(String s) {
  switch (s) {
    case 'intro':
      return Phase.intro;
    case 'independent':
      return Phase.independent;
    case 'discussion':
      return Phase.discussion;
    case 'voting':
      return Phase.voting;
    case 'synthesis':
      return Phase.synthesis;
    case 'complete':
      return Phase.complete;
    default:
      return Phase.idle;
  }
}
