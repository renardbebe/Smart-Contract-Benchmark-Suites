 
    function changeBalancesDB(address _newDB) public onlyOwner {
        balancesDB = CStore(_newDB);
    }

     
    function disableERC20() public onlyOwner {
        mErc20compatible = false;
        setInterfaceImplementation("ERC20Token", address(0));
    }

     
    function enableERC20() public onlyOwner {
        mErc20compatible = true;
        setInterfaceImplementation("ERC20Token", address(this));
    }

     
    function multiPartyTransfer(address[] calldata _toAddresses, uint256[] calldata _amounts) external erc20 {
         
        require(_toAddresses.length <= 255, "Unsupported number of addresses.");
         
        require(_toAddresses.length == _amounts.length, "Provided addresses does not equal to provided sums.");

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transfer(_toAddresses[i], _amounts[i]);
        }
    }

     
    function multiPartyTransferFrom(address _from, address[] calldata _toAddresses, uint256[] calldata _amounts) external erc20 {
         
        require(_toAddresses.length <= 255, "Unsupported number of addresses.");
         
        require(_toAddresses.length == _amounts.length, "Provided addresses does not equal to provided sums.");

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            transferFrom(_from, _toAddresses[i], _amounts[i]);
        }
    }

     
    function multiPartySend(address[] memory _toAddresses, uint256[] memory _amounts, bytes memory _userData) public {
         
        require(_toAddresses.length <= 255, "Unsupported number of addresses.");
         
        require(_toAddresses.length == _amounts.length, "Provided addresses does not equal to provided sums.");

        for (uint8 i = 0; i < _toAddresses.length; i++) {
            doSend(msg.sender,  msg.sender, _toAddresses[i], _amounts[i], _userData, "", true);
        }
    }

     
    function multiOperatorSend(address _from, address[] calldata _to, uint256[] calldata _amounts, bytes calldata _userData, bytes calldata _operatorData)
    external {
         
        require(_to.length <= 255, "Unsupported number of addresses.");
         
        require(_to.length == _amounts.length, "Provided addresses does not equal to provided sums.");

        for (uint8 i = 0; i < _to.length; i++) {
            require(isOperatorFor(msg.sender, _from), "Not an operator");  
            doSend(msg.sender, _from, _to[i], _amounts[i], _userData, _operatorData, true);
        }
    }
}

