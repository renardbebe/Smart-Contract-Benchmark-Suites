 

pragma solidity ^0.5.2;

contract FiatContract {

    mapping(uint => Token) public tokens;

    address payable public sender;
    address public creator;

    event NewPrice(uint id, string token);
    event DeletePrice(uint id);
    event UpdatedPrice(uint id);
    event RequestUpdate(uint id);
    event Donation(address from);

    struct Token {
        string name;
        uint256 eth;
        uint256 usd;
        uint256 eur;
        uint256 mxn;
        uint timestamp;
    }

     
    constructor(address payable _sender)public {
        creator = msg.sender;
        sender = _sender;  
    }

     
    function getToken(uint _id) internal view returns  (Token memory) {
        return  tokens[_id];
    }

     
    function ETH(uint _id) public view returns  (uint256) {
        return tokens[_id].eth;
    }

     
    function USD(uint _id) public view returns (uint256) {
        return tokens[_id].usd;
    }

     
    function EUR(uint _id) public view returns (uint256) {
        return tokens[_id].eur;
    }

     
    function MXN(uint _id) public view returns (uint256) {
        return tokens[_id].mxn;
    }

     
    function updatedAt(uint _id)public view returns (uint) {
        return tokens[_id].timestamp;
    }

     
    function update(uint id, string calldata _token, uint256 eth, uint256 usd, uint256 eur, uint256 mxn) external {
        require(msg.sender==sender);
        tokens[id] = Token(_token, eth, usd, eur, mxn, now);
        emit NewPrice(id, _token);
    }
     

     
    function deleteToken(uint id) public {
        require(msg.sender==creator);
        emit DeletePrice(id);
        delete tokens[id];
    }

     
    function changeCreator(address _creator)public{
        require(msg.sender==creator);
        creator = _creator;
    }

     
    function changeSender(address payable _sender)public{
        require(msg.sender==creator);
        sender = _sender;
    }


     
    function() external payable {

    }

     
     
    function requestUpdate(uint id) external payable {
        uint256 weiAmount = tokens[0].usd * 35;
        require(msg.value >= weiAmount);
        sender.transfer(address(this).balance);
        emit RequestUpdate(id);
    }

     
    function donate() external payable {
        require(msg.value >= 0);
        sender.transfer(address(this).balance);
        emit Donation(msg.sender);
    }

}