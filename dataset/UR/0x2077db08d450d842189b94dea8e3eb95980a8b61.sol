 

 

pragma solidity ^0.4.21;

contract SafePromo {

	address public owner;
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function SafePromo() public {

		owner = msg.sender;

	}

	function promo(address[] _recipients) public {

		require(msg.sender == owner);

		for(uint256 i = 0; i < _recipients.length; i++){

			_recipients[i].transfer(7777777777);
			emit Transfer(address(this), _recipients[i], 77777777777);

		}

	}

	function() public payable{ }

}