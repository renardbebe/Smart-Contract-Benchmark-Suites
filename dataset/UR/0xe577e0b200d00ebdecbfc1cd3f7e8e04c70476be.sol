 

pragma solidity 0.5.7;

 

 
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

 
contract TokenRecipient {

    function onTokenTransfer(address _from, uint256 _value, bytes calldata _extraData) external returns (bool);
     

}

 
contract CryptonomicaVerification {

     
    function revokedOn(address _address) external view returns (uint unixTime);

    function keyCertificateValidUntil(address _address) external view returns (uint unixTime);

}

contract xEuro {

     
    using SafeMath for uint256;

    CryptonomicaVerification public cryptonomicaVerification;

     

     
    string public constant name = "xEuro";

     
    string public constant symbol = "xEUR";

     
    uint8 public constant decimals = 0;  

     
    uint256 public totalSupply = 0;

     
     
    mapping(address => uint256) public balanceOf;

     
    mapping(address => mapping(address => uint256)) public allowance;

     

     
    mapping(address => bool) public isAdmin;

     
    mapping(address => bool) public canMint;

     
    mapping(address => bool) public canTransferFromContract;

     
    mapping(address => bool) public canBurn;

     

     

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    event DataSentToAnotherContract(address indexed _from, address indexed _toContract, bytes _extraData);

     
     

     
    function approve(address _spender, uint256 _value) public returns (bool success){

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

     
    function approve(address _spender, uint256 _currentValue, uint256 _value) external returns (bool success){

        require(allowance[msg.sender][_spender] == _currentValue);

        return approve(_spender, _value);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool success){
        return transferFrom(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

         
         
         

        require(_to != address(0));

         
        require(
            msg.sender == _from
        || _value <= allowance[_from][msg.sender]
        || (_from == address(this) && canTransferFromContract[msg.sender]),
            "Sender not authorized");

         
        require(_value <= balanceOf[_from], "Account doesn't have required amount");

        if (_to == address(this)) { 

             
            require(_from == msg.sender, "Only token holder can do this");

            require(_value >= minExchangeAmount, "Value is less than min. exchange amount");

             
             
            tokensInEventsCounter++;
            emit TokensIn(
                _from,
                _value,
                tokensInEventsCounter
            );

             
             
            tokensInTransfer[tokensInEventsCounter].from = _from;
            tokensInTransfer[tokensInEventsCounter].value = _value;
             
            tokensInTransfer[tokensInEventsCounter].receivedOn = now;

        }

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

         
        if (_from != msg.sender && _from != address(this)) {
            allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        }

        emit Transfer(_from, _to, _value);

        return true;
    }

     

     
    function transferAndCall(address _to, uint256 _value, bytes memory _extraData) public returns (bool success){

        TokenRecipient receiver = TokenRecipient(_to);

        if (transferFrom(msg.sender, _to, _value)) {

             
            if (receiver.onTokenTransfer(msg.sender, _value, _extraData)) {
                emit DataSentToAnotherContract(msg.sender, _to, _extraData);
                return true;
            }

        }

        return false;
    }

     
    function transferAllAndCall(address _to, bytes calldata _extraData) external returns (bool){
        return transferAndCall(_to, balanceOf[msg.sender], _extraData);
    }

     

     
    event CryptonomicaArbitrationContractAddressChanged(address from, address to, address indexed by);

     
    function changeCryptonomicaVerificationContractAddress(address _newAddress) public returns (bool success) {

        require(isAdmin[msg.sender], "Only admin can do that");

        emit CryptonomicaArbitrationContractAddressChanged(address(cryptonomicaVerification), _newAddress, msg.sender);

        cryptonomicaVerification = CryptonomicaVerification(_newAddress);

        return true;
    }

     
    event AdminAdded(address indexed by, address indexed newAdmin);

    function addAdmin(address _newAdmin) public returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");
        require(_newAdmin != address(0), "Address can not be zero-address");

        require(cryptonomicaVerification.keyCertificateValidUntil(_newAdmin) > now, "New admin has to be verified on Cryptonomica.net");

         
        require(cryptonomicaVerification.revokedOn(_newAdmin) == 0, "Verification for this address was revoked, can not add");

        isAdmin[_newAdmin] = true;

        emit AdminAdded(msg.sender, _newAdmin);

        return true;
    }

     
    event AdminRemoved(address indexed by, address indexed _oldAdmin);

     
    function removeAdmin(address _oldAdmin) external returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");

         
        require(msg.sender != _oldAdmin, "Admin can't remove himself");

        isAdmin[_oldAdmin] = false;

        emit AdminRemoved(msg.sender, _oldAdmin);

        return true;
    }

     
    uint256 public minExchangeAmount;

     
    event MinExchangeAmountChanged (address indexed by, uint256 from, uint256 to);

     
    function changeMinExchangeAmount(uint256 _minExchangeAmount) public returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");

        uint256 from = minExchangeAmount;

        minExchangeAmount = _minExchangeAmount;

        emit MinExchangeAmountChanged(msg.sender, from, minExchangeAmount);

        return true;
    }

     
    event AddressAddedToCanMint(address indexed by, address indexed newAddress);

     
    function addToCanMint(address _newAddress) public returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");
        require(_newAddress != address(0), "Address can not be zero-address");

        canMint[_newAddress] = true;

        emit AddressAddedToCanMint(msg.sender, _newAddress);

        return true;
    }

    event AddressRemovedFromCanMint(address indexed by, address indexed removedAddress);

    function removeFromCanMint(address _addressToRemove) external returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");

        canMint[_addressToRemove] = false;

        emit AddressRemovedFromCanMint(msg.sender, _addressToRemove);

        return true;
    }

     
    event AddressAddedToCanTransferFromContract(address indexed by, address indexed newAddress);

    function addToCanTransferFromContract(address _newAddress) public returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");
        require(_newAddress != address(0), "Address can not be zero-address");

        canTransferFromContract[_newAddress] = true;

        emit AddressAddedToCanTransferFromContract(msg.sender, _newAddress);

        return true;
    }

    event AddressRemovedFromCanTransferFromContract(address indexed by, address indexed removedAddress);

    function removeFromCanTransferFromContract(address _addressToRemove) external returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");

        canTransferFromContract[_addressToRemove] = false;

        emit AddressRemovedFromCanTransferFromContract(msg.sender, _addressToRemove);

        return true;
    }

     
    event AddressAddedToCanBurn(address indexed by, address indexed newAddress);

    function addToCanBurn(address _newAddress) public returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");
        require(_newAddress != address(0), "Address can not be zero-address");

        canBurn[_newAddress] = true;

        emit AddressAddedToCanBurn(msg.sender, _newAddress);

        return true;
    }

    event AddressRemovedFromCanBurn(address indexed by, address indexed removedAddress);

    function removeFromCanBurn(address _addressToRemove) external returns (bool success){

        require(isAdmin[msg.sender], "Only admin can do that");

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

     
    function mintTokens(uint256 value, uint256 fiatInPaymentId) public returns (bool success){

        require(canMint[msg.sender], "Sender not authorized");

         
        require(!fiatInPaymentIds[fiatInPaymentId], "This fiat payment id is already used");

         
         

         
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

     
    function mintAndTransfer(uint256 _value, uint256 fiatInPaymentId, address _to) public returns (bool success){

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

     
    mapping(uint256 => burnTokensEvent) public burnTokensEvents;

     
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
    ) public returns (bool success){

         
         

        require(canBurn[msg.sender], "Sender not authorized");
        require(balanceOf[address(this)] >= value, "Account does not have required amount");

         
        require(!fiatOutPaymentIdsUsed[fiatOutPaymentId], "This fiat payment id is already used");

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

        fiatOutPaymentIdsUsed[fiatOutPaymentId] = true;

        return true;
    }

     
    constructor() public { 

         
        isAdmin[msg.sender] = true;

        addToCanMint(msg.sender);
        addToCanTransferFromContract(msg.sender);
        addToCanBurn(msg.sender);

        changeCryptonomicaVerificationContractAddress(0x846942953c3b2A898F10DF1e32763A823bf6b27f);
        addAdmin(0xD851d045d8Aee53EF24890afBa3d701163AcbC8B);

         
        changeMinExchangeAmount(12);
        mintAndTransfer(12, 0, msg.sender);
        transfer(msg.sender, 12);
        transfer(address(this), 12);
        burnTokens(12, 1, 0);

    }

}