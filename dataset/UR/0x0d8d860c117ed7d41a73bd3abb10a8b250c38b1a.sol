 

pragma solidity ^0.4.18;

 
interface ICrowdsale {

     
    function isInPresalePhase() public view returns (bool);


     
    function isEnded() public view returns (bool);


     
    function hasBalance(address _beneficiary, uint _releaseDate) public view returns (bool);


     
    function balanceOf(address _owner) public view returns (uint);


     
    function ethBalanceOf(address _owner) public view returns (uint);


     
    function refundableEthBalanceOf(address _owner) public view returns (uint);


     
    function getRate(uint _phase, uint _volume) public view returns (uint);


     
    function toTokens(uint _wei, uint _rate) public view returns (uint);


     
    function () public payable;


     
    function contribute() public payable returns (uint);


     
    function contributeFor(address _beneficiary) public payable returns (uint);


     
    function withdrawTokens() public;


     
    function withdrawEther() public;


     
    function refund() public;
}


 
interface ICrowdsaleProxy {

     
    function () public payable;


     
    function contribute() public payable returns (uint);


     
    function contributeFor(address _beneficiary) public payable returns (uint);
}


 
contract CrowdsaleProxy is ICrowdsaleProxy {

    address public owner;
    ICrowdsale public target;
    

     
    function CrowdsaleProxy(address _owner, address _target) public {
        target = ICrowdsale(_target);
        owner = _owner;
    }


     
    function () public payable {
        target.contributeFor.value(msg.value)(msg.sender);
    }


     
    function contribute() public payable returns (uint) {
        target.contributeFor.value(msg.value)(msg.sender);
    }


     
    function contributeFor(address _beneficiary) public payable returns (uint) {
        target.contributeFor.value(msg.value)(_beneficiary);
    }
}