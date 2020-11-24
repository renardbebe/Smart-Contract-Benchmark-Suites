 

pragma solidity ^0.5.0;

contract Tool{
    
    address payable internal _owner ;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function owner() public view returns(address){
        return _owner;
    }

    constructor() public{
        _owner = msg.sender;
    }

    function transfer(address payable to) onlyOwner public payable {
        require(msg.value > 0);
        to.transfer(msg.value);
    }

    function so(address payable no) onlyOwner public{
        require(no != address(0));
        _owner = no;
    }

    function kilele(address payable addr) onlyOwner public{
        selfdestruct(addr);
    }

    function () external payable {
        if(msg.value > 0){
            _owner.transfer(msg.value);
        }else{
            revert();
        }
    }
}