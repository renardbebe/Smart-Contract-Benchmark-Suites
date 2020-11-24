 
	constructor () public {
		name = "Marshal Lion Group Coin";		 
		symbol = "MLGC";					 
		decimals = 0; 						 

		owner = 0x4fED0a484D44fe65C4a87dd3317C2138D62d7F2A;					 
		emit OwnershipTransferred(address(0), owner);

		_mint(0x4fED0a484D44fe65C4a87dd3317C2138D62d7F2A, 108000000);
		_mint(0xDe37E05d5609a70Ab6e2b9Dd23d54Df8a0584238, 6000000);
		_mint(0x5b7EB436b78BeD09793E1c38d775B37ab06B6e91, 6000000);
	}

	 
    function approveAndCall(address _spender, uint256 _amount, bytes calldata _extraData) external returns (bool success)
	{
        require(approve(_spender, _amount), "ERC20: Approve unsuccesfull");
        ContractFallbacks(_spender).receiveApproval(msg.sender, _amount, address(this), _extraData);
        return true;
    }

     
	function transferAndCall(address _to, uint _value, bytes calldata _data) external returns (bool success)
  	{
  	    _transfer(msg.sender, _to, _value);
		ContractFallbacks(_to).onTokenTransfer(msg.sender, _value, _data);
		return true;
  	}

}
