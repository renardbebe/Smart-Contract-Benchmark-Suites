 

pragma solidity 0.4.24;


contract ERC20 {
	function transfer(address _to, uint256 _value) public returns (bool success);
	function balanceOf(address _owner) public returns (uint256 balance);
}


contract AirDrop {

	address public owner;

	modifier onlyOwner {
		require(msg.sender == owner, 'Invoker must be msg.sender');
		_;
	}

	constructor() public {
		owner = msg.sender;
	}

	 
	function transferOwnership(address _newOwner) public onlyOwner {
		require(_newOwner != address(0), "newOwner cannot be zero address");

		owner = _newOwner;
	}

	 
	function withdraw(address _token) public onlyOwner {
		require(_token != address(0), "Token address cannot be zero address");

		uint256 balance = ERC20(_token).balanceOf(address(this));

		require(balance > 0, "Cannot withdraw from a balance of zero");

		ERC20(_token).transfer(owner, balance);
	}

     
	function airdrop(address _token, uint256 _amount, address[] memory _targets) public onlyOwner {
		require(_targets.length > 0, 'Target addresses must not be 0');
		require(_targets.length <= 64, 'Target array length is too big');
		require
        (
			_amount * _targets.length <= ERC20(_token).balanceOf(address(this)), 
			'Airdrop contract does not have enough tokens to execute the airdrop'
		);

		for (uint8 target = 0; target < _targets.length; target++) {
			ERC20(_token).transfer(_targets[target], _amount);
		}
	}
}