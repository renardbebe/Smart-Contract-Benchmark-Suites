 

 

pragma solidity 0.5.8;

interface RouterInterface {
    function getPrototype() external view returns(address);
    function updateVersion(address _newPrototype) external returns(bool);
}

contract Resolver {
    address internal constant PLACEHOLDER = 0xc9b3f8a460436e8367Fbc7E7f3cFF4B34eaFE8D0;

    function () external payable {
        address prototype = RouterInterface(PLACEHOLDER).getPrototype();
        assembly {
            let calldatastart := 0
            calldatacopy(calldatastart, 0, calldatasize)
            let res := delegatecall(gas, prototype, calldatastart, calldatasize, 0, 0)
            let returndatastart := 0
            returndatacopy(returndatastart, 0, returndatasize)
            switch res case 0 { revert(returndatastart, returndatasize) }
                default { return(returndatastart, returndatasize) }
        }
    }
}