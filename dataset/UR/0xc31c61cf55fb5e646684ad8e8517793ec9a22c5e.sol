 

pragma solidity >=0.5.7 <0.6.0;

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
contract tokenRecipient {
    function tokenFallback(address _from, uint256 _value, bytes memory _extraData) public returns (bool);
}

contract xEuro {

     
    using SafeMath for uint256;

     

     
     
    string public name = "xEuro";

     
     
    string public symbol = "xEUR";

     
     
    uint8 public decimals = 0;  

     
     
     
    uint256 public totalSupply = 0;

     
     
    mapping(address => uint256) public balanceOf;

     
     
    mapping(address => mapping(address => uint256)) public allowance;

     

     
    mapping(address => bool) public isAdmin;

     
    mapping(address => bool) public canMint;

     
    mapping(address => bool) public canTransferFromContract;

     
    mapping(address => bool) public canBurn;

     
     
     
    constructor() public { 
        isAdmin[msg.sender] = true;
        canMint[msg.sender] = true;
        canTransferFromContract[msg.sender] = true;
        canBurn[msg.sender] = true;
    }

     
     

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

     
     

     
    function transfer(address _to, uint256 _value) public returns (bool){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

         
        require(_value >= 0);

         
        require(msg.sender == _from || _value <= allowance[_from][msg.sender] || (_from == address(this) && canTransferFromContract[msg.sender]));

         
        require(_value <= balanceOf[_from]);

        if (_to == address(this)) {
             
            require(_from == msg.sender);
        }

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender && _from != address(this)) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        if (_to == address(this) && _value > 0) {

            require(_value >= minExchangeAmount);

            tokensInEventsCounter++;
            tokensInTransfer[tokensInEventsCounter].from = _from;
            tokensInTransfer[tokensInEventsCounter].value = _value;
            tokensInTransfer[tokensInEventsCounter].receivedOn = now;

            emit TokensIn(
                _from,
                _value,
                tokensInEventsCounter
            );
        }

        emit Transfer(_from, _to, _value);

        return true;
    }

     

     
    function transferAndCall(address _to, uint256 _value, bytes memory _extraData) public returns (bool){

        tokenRecipient receiver = tokenRecipient(_to);

        if (transferFrom(msg.sender, _to, _value)) {

            if (receiver.tokenFallback(msg.sender, _value, _extraData)) {

                emit DataSentToAnotherContract(msg.sender, _to, _extraData);

                return true;

            }

        }
        return false;
    }

     
     
    function transferAllAndCall(address _to, bytes memory _extraData) public returns (bool){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     

     
    event AdminAdded(address indexed by, address indexed newAdmin); 
    function addAdmin(address _newAdmin) public returns (bool){
        require(isAdmin[msg.sender]);

        isAdmin[_newAdmin] = true;
        emit AdminAdded(msg.sender, _newAdmin);
        return true;
    }  
    event AdminRemoved(address indexed by, address indexed _oldAdmin); 
    function removeAdmin(address _oldAdmin) public returns (bool){
        require(isAdmin[msg.sender]);

         
        require(msg.sender != _oldAdmin);
        isAdmin[_oldAdmin] = false;
        emit AdminRemoved(msg.sender, _oldAdmin);
        return true;
    }

    uint256 minExchangeAmount = 12;  
    event minExchangeAmountChanged (address indexed by, uint256 from, uint256 to);  
    function changeMinExchangeAmount(uint256 _minExchangeAmount) public returns (bool){
        require(isAdmin[msg.sender]);

        uint256 from = minExchangeAmount;
        minExchangeAmount = _minExchangeAmount;
        emit minExchangeAmountChanged(msg.sender, from, minExchangeAmount);
        return true;
    }

     
    event AddressAddedToCanMint(address indexed by, address indexed newAddress);  
    function addToCanMint(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canMint[_newAddress] = true;
        emit AddressAddedToCanMint(msg.sender, _newAddress);
        return true;
    } 
    event AddressRemovedFromCanMint(address indexed by, address indexed removedAddress); 
    function removeFromCanMint(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canMint[_addressToRemove] = false;
        emit AddressRemovedFromCanMint(msg.sender, _addressToRemove);
        return true;
    }

     
    event AddressAddedToCanTransferFromContract(address indexed by, address indexed newAddress);  
    function addToCanTransferFromContract(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canTransferFromContract[_newAddress] = true;
        emit AddressAddedToCanTransferFromContract(msg.sender, _newAddress);
        return true;
    } 
    event AddressRemovedFromCanTransferFromContract(address indexed by, address indexed removedAddress); 
    function removeFromCanTransferFromContract(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canTransferFromContract[_addressToRemove] = false;
        emit AddressRemovedFromCanTransferFromContract(msg.sender, _addressToRemove);
        return true;
    }

     
    event AddressAddedToCanBurn(address indexed by, address indexed newAddress);  
    function addToCanBurn(address _newAddress) public returns (bool){
        require(isAdmin[msg.sender]);

        canBurn[_newAddress] = true;
        emit AddressAddedToCanBurn(msg.sender, _newAddress);
        return true;
    } 
    event AddressRemovedFromCanBurn(address indexed by, address indexed removedAddress); 
    function removeFromCanBurn(address _addressToRemove) public returns (bool){
        require(isAdmin[msg.sender]);

        canBurn[_addressToRemove] = false;
        emit AddressRemovedFromCanBurn(msg.sender, _addressToRemove);
        return true;
    }

     

     
    uint public mintTokensEventsCounter = 0; 
    struct MintTokensEvent {
        address mintedBy;  
        uint256 fiatInPaymentId;
        uint value;    
        uint on;     
        uint currentTotalSupply;
    }  
     
    mapping(uint256 => bool) public fiatInPaymentIds;

     
     
    mapping(uint256 => MintTokensEvent) public fiatInPaymentsToMintTokensEvent;

     
    mapping(uint256 => MintTokensEvent) public mintTokensEvent;  
    event TokensMinted(
        address indexed by,
        uint256 indexed fiatInPaymentId,
        uint value,
        uint currentTotalSupply,
        uint indexed mintTokensEventsCounter
    );

     
    function mintTokens(uint256 value, uint256 fiatInPaymentId) public returns (bool){

        require(canMint[msg.sender]);

         
        require(!fiatInPaymentIds[fiatInPaymentId]);

        require(value >= 0);
         
        totalSupply = totalSupply.add(value);
         
        balanceOf[address(this)] = balanceOf[address(this)].add(value);

        mintTokensEventsCounter++;
        mintTokensEvent[mintTokensEventsCounter].mintedBy = msg.sender;
        mintTokensEvent[mintTokensEventsCounter].fiatInPaymentId = fiatInPaymentId;
        mintTokensEvent[mintTokensEventsCounter].value = value;
        mintTokensEvent[mintTokensEventsCounter].on = block.timestamp;
        mintTokensEvent[mintTokensEventsCounter].currentTotalSupply = totalSupply;
         
        fiatInPaymentsToMintTokensEvent[fiatInPaymentId] = mintTokensEvent[mintTokensEventsCounter];

        emit TokensMinted(msg.sender, fiatInPaymentId, value, totalSupply, mintTokensEventsCounter);

        fiatInPaymentIds[fiatInPaymentId] = true;

        return true;

    }

     
    function mintAndTransfer(
        uint256 _value,
        uint256 fiatInPaymentId,
        address _to
    ) public returns (bool){

        if (mintTokens(_value, fiatInPaymentId) && transferFrom(address(this), _to, _value)) {
            return true;
        }
        return false;
    }

     
    uint public tokensInEventsCounter = 0; 
    struct TokensInTransfer { 
        address from;  
        uint value;    
        uint receivedOn;  
    }  
    mapping(uint256 => TokensInTransfer) public tokensInTransfer;  
    event TokensIn(
        address indexed from,
        uint256 value,
        uint256 indexed tokensInEventsCounter
    ); 

    uint public burnTokensEventsCounter = 0; 
    struct burnTokensEvent {
        address by;  
        uint256 value;    
        uint256 tokensInEventId;
        uint256 fiatOutPaymentId;
        uint256 burnedOn;  
        uint256 currentTotalSupply;
    }  
    mapping(uint => burnTokensEvent) public burnTokensEvents;

     
    mapping(uint256 => bool) public fiatOutPaymentIdsUsed;  

    event TokensBurned(
        address indexed by,
        uint256 value,
        uint256 indexed tokensInEventId,
        uint256 indexed fiatOutPaymentId,
        uint burnedOn,  
        uint currentTotalSupply
    );

     
    function burnTokens(
        uint256 value,
        uint256 tokensInEventId,
        uint256 fiatOutPaymentId
    ) public returns (bool){

        require(canBurn[msg.sender]);

        require(value >= 0);
        require(balanceOf[address(this)] >= value);

         
        require(!fiatOutPaymentIdsUsed[fiatOutPaymentId]);

        balanceOf[address(this)] = balanceOf[address(this)].sub(value);
        totalSupply = totalSupply.sub(value);

        burnTokensEventsCounter++;
        burnTokensEvents[burnTokensEventsCounter].by = msg.sender;
        burnTokensEvents[burnTokensEventsCounter].value = value;
        burnTokensEvents[burnTokensEventsCounter].tokensInEventId = tokensInEventId;
        burnTokensEvents[burnTokensEventsCounter].fiatOutPaymentId = fiatOutPaymentId;
        burnTokensEvents[burnTokensEventsCounter].burnedOn = block.timestamp;
        burnTokensEvents[burnTokensEventsCounter].currentTotalSupply = totalSupply;

        emit TokensBurned(msg.sender, value, tokensInEventId, fiatOutPaymentId, block.timestamp, totalSupply);

        fiatOutPaymentIdsUsed[fiatOutPaymentId];

        return true;
    }

}