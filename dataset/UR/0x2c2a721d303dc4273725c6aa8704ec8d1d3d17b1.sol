 

pragma solidity ^0.4.24;

 

 
contract Ownable {
    address emitter;
    address administrator;

     
    function setEmitter(address _emitter) internal {
        require(_emitter != address(0));
        require(emitter == address(0));
        emitter = _emitter;
    }

     
    function setAdministrator(address _administrator) internal {
        require(_administrator != address(0));
        require(administrator == address(0));
        administrator = _administrator;
    }

     
    modifier onlyEmitter() {
        require(msg.sender == emitter);
        _;
    }

     
    modifier onlyAdministrator() {
        require(msg.sender == administrator);
        _;
    }

     
    function transferOwnership(address _emitter, address _administrator) public onlyAdministrator {
        require(_emitter != _administrator);
        require(_emitter != emitter);
        require(_emitter != address(0));
        require(_administrator != address(0));
        emitter = _emitter;
        administrator = _administrator;
    }
}

 

contract GlitchGoonsProxy is Ownable {

    constructor (address _emitter, address _administrator) public {
        setEmitter(_emitter);
        setAdministrator(_administrator);
    }

    function deposit() external payable {
        emitter.transfer(msg.value);
    }

    function transfer(address _to) external payable {
        _to.transfer(msg.value);
    }
}