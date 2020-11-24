 

pragma solidity ^0.4.24;


contract Controlled {

    address public controller;

    constructor() public {
        controller = msg.sender;
    }

    function changeController(address _newController) public only_controller {
        controller = _newController;
    }
    
    function getController() constant public returns (address) {
        return controller;
    }

    modifier only_controller { 
        require(msg.sender == controller);
        _; 
    }
}

contract CallContract is Controlled {
    
    function callFrozen(address contractAddr, address[] _addrs, bool _isFrozen) only_controller public{
        bytes4 methodId = bytes4(keccak256("freezeAccount(address, bool)"));
		for (uint i = 0; i < _addrs.length; i++)
            contractAddr.call(methodId, _addrs[i], _isFrozen);
    }
	
	function changeContractController(address contractAddr, address _newController) public only_controller {
        bytes4 methodId = bytes4(keccak256("changeController(address)"));
		contractAddr.call(_newController);
    }
}