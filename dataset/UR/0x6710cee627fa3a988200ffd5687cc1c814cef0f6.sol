 
	constructor () public {
		name = "Fotrem Capital Token";	 
		symbol = "FCQ";					 
		decimals = 0; 					 

		owner = msg.sender;				 
		emit OwnershipTransferred(address(0), owner);

		_mint(address(this), 210000000);	 
		uint locktime = now + 180 * 1 days;  

		_lock(locktime, 5250000, 0x8BD28e698ae9B94C4014e545788d823E2831E198);  	 
		_lock(locktime, 5250000, 0x002D24862F0E075b987b22E98575f4Fe29F5e825);	 
		_lock(locktime, 5250000, 0xDec2Ced03dba3c7fa13bb1d9b1c4DC60c23fE09A);	 
		_lock(locktime, 5250000, 0x34B25D01aCc061f2aFA097F6c53D01892dB9e61f);	 
		_transfer(address(this), 0x2C44Cbb56e5Dc4A2C152BF91Cd35ca8481E9a614, totalSupply()-lockedBalance);  
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
