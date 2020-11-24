 
    constructor(RaeToken token) Ownable() public 
    {
        _token = token;
    }

     
    function bulkMintAggregator(address[] memory addresses, uint256[] memory values, address[] memory aggregators) public onlyOwner returns (bool)
    {
        if(_token.period() != 0)
        {
            uint256 totalSent = 0;
            require(addresses.length > 0);
            require(addresses.length == values.length);
            require(addresses.length == aggregators.length);

            uint256 addrSize = addresses.length;
            uint256 size = addrSize.add(addrSize);
            address[] memory bulkAddresses = new address[](size);
            uint256[] memory bulkValues = new uint256[](size);

            uint256 j = 0;
            for(uint256 i = 0; i < addresses.length; ++i)
            {
                uint256 aggregatorReward = values[i].mul(_pct).div(100);
                uint256 creatorReward = values[i].sub(aggregatorReward);
                totalSent = totalSent.add(aggregatorReward + creatorReward);
                
                 
                bulkAddresses[j] = addresses[i];
                bulkValues[j] = creatorReward;

                bulkAddresses[j+1] = aggregators[i];
                bulkValues[j+1] = aggregatorReward;

                 
                j = j + 2;
            }
            require(totalSent <= _token.remainingInPeriod());
            _token.mintBulk(bulkAddresses, bulkValues);  
            return true;
        }
        else 
        {
            _bulkMintFirstPeriod(addresses, values);
            return true;
        }
    }

     
    function _bulkMintFirstPeriod(address[] memory addresses, uint256[] memory values) internal returns (bool) {
        require(_token.period() == 0);
        require(addresses.length != 0);
        require(addresses.length == values.length);

        uint256 totalSent = 0;
        for(uint256 i =0; i < addresses.length; ++i) totalSent = totalSent.add(values[i]);
        require(totalSent <= _token.remainingInPeriod());
        _token.mintBulk(addresses, values);
        return true;
    }



       
    function addMinter(address addr) external onlyOwner returns (bool)
    {
        _token.addMinter(addr);
        return true;
    }

     
    function renounceMintingRole() external onlyOwner returns (bool)
    {
        _token.renounceMinter();
        return true;
    }

    
    function period() external view returns (uint256){
        return _token.period();
    }

    function mintAmount() external view returns (uint256){
        return _token.mintAmount();
    }


    function tokensRemainingInPeriod() external view returns (uint256) {
        return _token.remainingInPeriod();
    }

    function tokensInPeriod() external view returns (uint256) {
        return _token.totalInPeriod();
    }

     
    function token() external view returns (address)
    {
        return address(_token);
    }


    

    


}