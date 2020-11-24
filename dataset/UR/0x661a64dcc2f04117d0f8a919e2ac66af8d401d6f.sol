 

pragma solidity 0.4.25;

 

 

 

 

 

 

 

 

 

contract ERC20_Basic {

    function totalSupply() public view returns (uint256);
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Cryptohunt is ERC20_Basic {

	bool public _hasBeenSolved = false;
	uint256 public _launchedTime;
	uint256 public _solvedTime;

	string public constant name = "Cryptohunt";
	string public constant symbol = "P4D Riddle";
	uint8 public constant decimals = 18;

	address constant private src = 0x058a144951e062FC14f310057D2Fd9ef0Cf5095b;
	uint256 constant private amt = 1e18;

	event Log(string msg);

	constructor() public {
		emit Transfer(address(this), src, amt);
		_launchedTime = now;
	}

	function attemptToSolve(string answer) public {
		bytes32 hash = keccak256(abi.encodePacked(answer));
		if (hash == 0x6fd689cdf2f367aa9bd63f9306de49f00479b474f606daed7c015f3d85ff4e40) {
			if (!_hasBeenSolved) {
				emit Transfer(src, address(0x0), amt);
				emit Log("Well done! You've deserved this!");
				emit Log(answer);
				_hasBeenSolved = true;
				_solvedTime = now;
			}
			msg.sender.transfer(address(this).balance);
		} else {
			emit Log("Sorry, but that's not the correct answer!");
		}
	}

	function() public payable {
		 
	}

	function totalSupply() public view returns (uint256) {
		return (_hasBeenSolved ? 0 : amt);
	}

	function balanceOf(address owner) public view returns (uint256) {
		return (_hasBeenSolved || owner != src ? 0 : amt);
	}

	function transfer(address, uint256) public returns (bool) {
		return false;
	}

	 
}

 