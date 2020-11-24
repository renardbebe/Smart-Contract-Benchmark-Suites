 
	constructor () public {
		name = "Wolfs Group AG";
		symbol = "WLF";
		decimals = 0;

		owner = 0x7fd429DBb710674614A35e967788Fa3e23A5c1C9;
		emit OwnershipTransferred(address(0), owner);

		_mint(0xc7eEef150818b5D3301cc93a965195F449603805, 15000000);
		_mint(0x7fd429DBb710674614A35e967788Fa3e23A5c1C9, 135000000);
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
