 
	function burn(uint256 amount) public onlyOwner {
		_burn(_msgSender(), amount);
	}

	 
	function burnFrom(address account, uint256 amount) public onlyOwner {
		_burnFrom(account, amount);
	}

	 
	function mintTo(address account, uint256 amount) public onlyOwner returns (bool) {
		_mint(account, amount);
		return true;
	}

	 
	function mint(uint256 amount) public onlyOwner returns (bool) {
		_mint(_msgSender(), amount);
		return true;
	}

	 
	function transferAnyERC20Token(address tokenAddress, uint256 amount) public onlyOwner returns (bool) {
		return ERC20(tokenAddress).transfer(owner(), amount);
	}
}