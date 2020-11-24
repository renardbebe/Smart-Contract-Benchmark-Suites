 

pragma solidity 0.4.24;

 

contract Destiny {
    function fight(bytes32 cat1, bytes32 cat2, bytes32 entropy) public returns (bytes32 winner);
}

contract KittyInterface {
    function approve(address _to, uint256 _tokenId) public;
	function transfer(address to, uint256 kittyId);
	function transferFrom(address from, address to, uint256 kittyId);
	function getKitty(uint256 _id) external view returns (bool isGestating, bool isReady, uint256 cooldownIndex, uint256 nextActionAt, uint256 siringWithId, uint256 birthTime, uint256 matronId, uint256 sireId, uint256 generation, uint256 genes);
}

contract Random {
   
  function bitSlice(uint256 n, uint256 bits, uint256 slot) public pure returns(uint256) {
      uint256 offset = slot * bits;
       
      uint256 mask = uint256((2**bits) - 1) << offset;
       
      return uint256((n & mask) >> offset);
  }

   
  function maxRandom(uint256 sourceBlock) public view returns (uint256 randomNumber) {
    require(block.number > sourceBlock);
    return uint256(block.blockhash(sourceBlock));
  }

  function random(uint256 upper) public view returns (uint256 randomNumber) {
    return random(upper, block.number - 1);
  }

   
   
  function random(uint256 upper, uint256 sourceBlock) public returns (uint256 randomNumber) {
    return maxRandom(sourceBlock) % upper;
  }
}


contract KittyArena is Random {
	struct Player {
		uint256 kitty;
		address addr;
	}

	struct Game {
		Player player1;
		Player player2;
		uint256 fightBlock;
		address winner;
	}

	KittyInterface public ck;
	Destiny destiny;
	Game[] public games;

	address constant public TIE = address(-2);

	event KittyEntered(uint256 indexed gameId, uint256 indexed kittyId, address indexed owner);
	event FightStarted(uint256 indexed gameId, uint256 fightBlock);
	event FightResolved(uint256 indexed gameId, address indexed winner);

	constructor (KittyInterface _ck, Destiny _destiny) public {
		ck = _ck;
		destiny = _destiny;
	}

	function enter(uint256 kitty) external {
		ck.transferFrom(msg.sender, this, kitty);
		Player storage player;
		Game storage game;

		if (games.length > 0 && games[games.length - 1].fightBlock == 0) {
			 
			game = games[games.length - 1];
			game.player2 = Player(kitty, msg.sender);
			game.fightBlock = block.number;

			player = game.player2;

			emit FightStarted(games.length - 1, game.fightBlock);
		} else {
			games.length += 1;
			game = games[games.length - 1];
			game.player1 = Player(kitty, msg.sender);

			player = game.player1;
		}

		emit KittyEntered(games.length - 1, player.kitty, player.addr);
	}

	function resolve(uint256 gameId) external {
		Game storage game = games[gameId];
		require(game.winner == address(0));
        require(game.player1.addr != address(0));
        require(game.player2.addr != address(0));

		game.winner = getWinner(gameId);
		
		ck.transfer(game.winner == TIE ? game.player1.addr : game.winner, game.player1.kitty);
		ck.transfer(game.winner == TIE ? game.player2.addr : game.winner, game.player2.kitty);

		emit FightResolved(gameId, game.winner);
	}

	function getWinner(uint256 gameId) public view returns (address) {
		Game storage game = games[gameId];
		if (game.winner != address(0)) {
			return game.winner;
		}

		bytes32 genes1 = catGenes(game.player1.kitty);
		bytes32 genes2 = catGenes(game.player2.kitty);

		require(block.number > game.fightBlock);
		bytes32 seed = bytes32(maxRandom(game.fightBlock));
		
		 
		 
		if (seed == bytes32(0)) {
			return TIE;
		}

		bytes32 winnerGenes = destiny.fight(genes1, genes2, seed);

		if (winnerGenes == genes1) {
			return game.player1.addr;
		} 

		if (winnerGenes == genes2) { 
			return game.player2.addr;
		}

		 
		 
		return TIE;
	}

	function catGenes(uint256 kitty) private view returns (bytes32 genes) {
		var (,,,,,,,,,_genes) = ck.getKitty(kitty);
		genes = bytes32(_genes);
	}
}