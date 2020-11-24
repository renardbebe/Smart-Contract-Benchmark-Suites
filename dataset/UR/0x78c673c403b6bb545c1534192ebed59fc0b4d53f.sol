 
	function burn(uint256 amount) public onlyOwner returns (bool) {
		_burn(msg.sender, amount);
		return true;
	}

	 
	function mint(address account, uint256 amount) public onlyOwner returns (bool) {
		_mint(account, amount);
		return true;
	}

	 
	function mint(uint256 amount) public onlyOwner returns (bool) {
		_mint(msg.sender, amount);
		return true;
	}

	 
	function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool) {
		return ERC20(tokenAddress).transfer(owner, tokens);
	}
}