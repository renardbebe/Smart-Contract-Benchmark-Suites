 
    constructor (uint256 cap, uint256 init) public ERC20Capped(cap) {
        require(cap > 1000000000000000000, "S3Coin: cap must greater than 10^18");

         
        mint(msg.sender, init);
    }

     
    function stake(uint32 id, address beneficiary, uint256 amount, uint256 releaseAmount, uint32 releaseTime)
        public onlyMinter returns (address) {
        require(_stakes[id] == address(0), "S3Coin: stake with ID already exist");
        require(balanceOf(msg.sender) >= amount, "S3Coin: there is not enough tokens to stake");
        require(amount >= releaseAmount, "S3Coin: there is not enough tokens to stake");

         
        S3Stake newStake = new S3Stake(S3Coin(address(this)), beneficiary, releaseAmount, releaseTime);

        emit NewStake(address(newStake));

         
        require(transfer(address(newStake), amount), "S3Coin: transfer tokens to new stake failed");

         
        _stakeCount += 1;
        _stakeTotal = _stakeTotal.add(amount);
        _stakes[id] = address(newStake);

        return _stakes[id];
    }

     
    function stakeAddress(uint32 id) public view returns (address) {
        return _stakes[id];
    }

     
    function stakeCount() public view returns (uint) {
        return _stakeCount;
    }

     
    function stakeTotal() public view returns (uint256) {
        return _stakeTotal;
    }

}