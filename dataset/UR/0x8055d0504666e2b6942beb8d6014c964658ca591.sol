 

pragma solidity 0.4.15;

 

contract FiatContract {

    mapping(uint => Token) public tokens;

    address public sender;
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
        uint256 gbp;
        uint block;
    }

     
    function FiatContract() {
        creator = msg.sender;
        sender = msg.sender;
    }

     
    function getToken(uint _id) internal constant returns (Token) {
        return tokens[_id];
    }

     
    function ETH(uint _id) constant returns (uint256) {
        return tokens[_id].eth;
    }

     
    function USD(uint _id) constant returns (uint256) {
        return tokens[_id].usd;
    }

     
    function EUR(uint _id) constant returns (uint256) {
        return tokens[_id].eur;
    }

     
    function GBP(uint _id) constant returns (uint256) {
        return tokens[_id].gbp;
    }

     
    function updatedAt(uint _id) constant returns (uint) {
        return tokens[_id].block;
    }

     
    function update(uint id, string _token, uint256 eth, uint256 usd, uint256 eur, uint256 gbp) external {
        require(msg.sender==sender);
        tokens[id] = Token(_token, eth, usd, eur, gbp, block.number);
        NewPrice(id, _token);
    }

     
    function deleteToken(uint id) {
        require(msg.sender==creator);
        DeletePrice(id);
        delete tokens[id];
    }

     
    function changeCreator(address _creator){
        require(msg.sender==creator);
        creator = _creator;
    }

     
    function changeSender(address _sender){
        require(msg.sender==creator);
        sender = _sender;
    }

     
    function execute(address _to, uint _value, bytes _data) external returns (bytes32 _r) {
        require(msg.sender==creator);
        require(_to.call.value(_value)(_data));
        return 0;
    }

     
    function() payable {

    }

     
     
    function requestUpdate(uint id) external payable {
        uint256 weiAmount = tokens[0].usd * 35;
        require(msg.value >= weiAmount);
        sender.transfer(msg.value);
        RequestUpdate(id);
    }

     
    function donate() external payable {
        require(msg.value >= 0);
        sender.transfer(msg.value);
        Donation(msg.sender);
    }

}