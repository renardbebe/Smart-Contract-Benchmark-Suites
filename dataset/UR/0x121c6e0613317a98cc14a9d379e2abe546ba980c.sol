 

pragma solidity ^0.4.19;

contract Multiownable {

     

    uint256 public howManyOwnersDecide;
    address[] public owners;
    bytes32[] public allOperations;
    address insideOnlyManyOwners;
    
     
    mapping(address => uint) ownersIndices;  
    mapping(bytes32 => uint) allOperationsIndicies;
    
     
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;
    
     

    event OwnershipTransferred(address[] previousOwners, address[] newOwners);

     

    function isOwner(address wallet) public constant returns(bool) {
        return ownersIndices[wallet] > 0;
    }

    function ownersCount() public constant returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public constant returns(uint) {
        return allOperations.length;
    }

     

     
    modifier onlyAnyOwner {
        require(isOwner(msg.sender));
        _;
    }

     
    modifier onlyManyOwners {
        if (insideOnlyManyOwners == msg.sender) {
            _;
            return;
        }
        require(isOwner(msg.sender));

        uint ownerIndex = ownersIndices[msg.sender] - 1;
        bytes32 operation = keccak256(msg.data);
        
        if (votesMaskByOperation[operation] == 0) {
            allOperationsIndicies[operation] = allOperations.length;
            allOperations.push(operation);
        }
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) == 0);
        votesMaskByOperation[operation] |= (2 ** ownerIndex);
        votesCountByOperation[operation] += 1;

         
        if (votesCountByOperation[operation] == howManyOwnersDecide) {
            deleteOperation(operation);
            insideOnlyManyOwners = msg.sender;
            _;
            insideOnlyManyOwners = address(0);
        }
    }

     

    function Multiownable() public {
        owners.push(msg.sender);
        ownersIndices[msg.sender] = 1;
        howManyOwnersDecide = 1;
    }

     

     
    function deleteOperation(bytes32 operation) internal {
        uint index = allOperationsIndicies[operation];
        if (allOperations.length > 1) {
            allOperations[index] = allOperations[allOperations.length - 1];
            allOperationsIndicies[allOperations[index]] = index;
        }
        allOperations.length--;
        
        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
    }

     

     
    function cancelPending(bytes32 operation) public onlyAnyOwner {
        uint ownerIndex = ownersIndices[msg.sender] - 1;
        require((votesMaskByOperation[operation] & (2 ** ownerIndex)) != 0);
        
        votesMaskByOperation[operation] &= ~(2 ** ownerIndex);
        votesCountByOperation[operation]--;
        if (votesCountByOperation[operation] == 0) {
            deleteOperation(operation);
        }
    }

     
    function transferOwnership(address[] newOwners) public {
        transferOwnershipWithHowMany(newOwners, newOwners.length);
    }

     
    function transferOwnershipWithHowMany(address[] newOwners, uint256 newHowManyOwnersDecide) public onlyManyOwners {
        require(newOwners.length > 0);
        require(newOwners.length <= 256);
        require(newHowManyOwnersDecide > 0);
        require(newHowManyOwnersDecide <= newOwners.length);
        for (uint i = 0; i < newOwners.length; i++) {
            require(newOwners[i] != address(0));
        }

        OwnershipTransferred(owners, newOwners);

         
        for (i = 0; i < owners.length; i++) {
            delete ownersIndices[owners[i]];
        }
        for (i = 0; i < newOwners.length; i++) {
            require(ownersIndices[newOwners[i]] == 0);
            ownersIndices[newOwners[i]] = i + 1;
        }
        owners = newOwners;
        howManyOwnersDecide = newHowManyOwnersDecide;

         
        for (i = 0; i < allOperations.length; i++) {
            delete votesMaskByOperation[allOperations[i]];
            delete votesCountByOperation[allOperations[i]];
            delete allOperationsIndicies[allOperations[i]];
        }
        allOperations.length = 0;
    }

}

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract PELOExtensionInterface is owned {

    event ExtensionCalled(bytes32[8] params);

    address public ownerContract;

    function PELOExtensionInterface(address _ownerContract) public {
        ownerContract = _ownerContract;
    }
    
    function ChangeOwnerContract(address _ownerContract) onlyOwner public {
        ownerContract = _ownerContract;
    }
    
    function Operation(uint8 opCode, bytes32[8] params) public returns (bytes32[8] result) {}
}

contract PELOExtension1 is PELOExtensionInterface {

    function PELOExtension1(address _ownerContract) PELOExtensionInterface(_ownerContract) public {} 
    
    function Operation(uint8 opCode, bytes32[8] params) public returns (bytes32[8] result) {
        if(opCode == 1) {
            ExtensionCalled(params);
            return result;
        }
        else if(opCode == 2) {
            ExtensionCalled(params);
            return result;
        }
        else {
            return result;
        }
    }
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
     
    string public name;
    string public symbol;
    uint8 public decimals = 18;
     
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);

     
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[msg.sender] = totalSupply;                 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);      
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);    
        balanceOf[msg.sender] -= _value;             
        totalSupply -= _value;                       
        Burn(msg.sender, _value);
        return true;
    }

     
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] -= _value;                          
        allowance[_from][msg.sender] -= _value;              
        totalSupply -= _value;                               
        Burn(_from, _value);
        return true;
    }
}

 
 
 

contract PELOCoinToken is Multiownable, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    
    bool public userInitialized = false;
    
    PELOExtensionInterface public peloExtenstion;
    
    struct PELOMember {
        uint32 id;
        bytes32 nickname;
        address ethAddr;

         
        uint peloAmount;

         
        uint peloBonus;

         
        uint bitFlag;

        uint32 expire;
        bytes32 extraData1;
        bytes32 extraData2;
        bytes32 extraData3;
    }
    
    uint8 public numMembers;

    mapping (address => bool) public frozenAccount;

    mapping (address => PELOMember) public PELOMemberMap;
    mapping (uint32 => address) public PELOMemberIDMap;

     
    event FrozenFunds(address target, bool frozen);

     
    function PELOCoinToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function GetUserNickName(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.nickname;
    }

    function GetUserID(address _addr) constant public returns(uint32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.id;
    }

    function GetUserPELOAmount(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.peloAmount;
    }

    function GetUserPELOBonus(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.peloBonus;
    }

    function GetUserBitFlag(address _addr) constant public returns(uint) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.bitFlag;
    }

    function TestUserBitFlag(address _addr, uint _flag) constant public returns(bool) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return (data.bitFlag & _flag) == _flag;
    }
    
    function GetUserExpire(address _addr) constant public returns(uint32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.expire;
    }
    
    function GetUserExtraData1(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData1;
    }
    
    function GetUserExtraData2(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData2;
    }
    
    function GetUserExtraData3(address _addr) constant public returns(bytes32) {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember memory data = PELOMemberMap[_addr]; 
        
        return data.extraData3;
    }

    function UpdateUserNickName(address _addr, bytes32 _newNickName) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.nickname = _newNickName;
    }

    function UpdateUserPELOAmount(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.peloAmount = _newValue;
    }

    function UpdateUserPELOBonus(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.peloBonus = _newValue;
    }

    function UpdateUserBitFlag(address _addr, uint _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.bitFlag = _newValue;
    }

    function UpdateUserExpire(address _addr, uint32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.expire = _newValue;
    }

    function UpdateUserExtraData1(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData1 = _newValue;
    }

    function UpdateUserExtraData2(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData2 = _newValue;
    }

    function UpdateUserExtraData3(address _addr, bytes32 _newValue) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);
        PELOMember storage data = PELOMemberMap[_addr]; 
        
        data.extraData3 = _newValue;
    }

    function DeleteUserByAddr(address _addr) onlyManyOwners public {
        require(PELOMemberMap[_addr].id > 0);

        delete PELOMemberIDMap[PELOMemberMap[_addr].id];
        delete PELOMemberMap[_addr];

        numMembers--;
        assert(numMembers >= 0);
    }

    function DeleteUserByID(uint32 _id) onlyManyOwners public {
        require(PELOMemberIDMap[_id] != 0x0);
        address addr = PELOMemberIDMap[_id];
        require(PELOMemberMap[addr].id > 0);

        delete PELOMemberMap[addr];
        delete PELOMemberIDMap[_id];
        
        numMembers--;
        assert(numMembers >= 0);
    }

    function initializeUsers() onlyManyOwners public {
        if(!userInitialized) {

            userInitialized = true;
        }
    }
            
    function insertNewUser(uint32 _id, bytes32 _nickname, address _ethAddr, uint _peloAmount, uint _peloBonus, uint _bitFlag, uint32 _expire, bool fWithTransfer) onlyManyOwners public {

        PELOMember memory data; 

        require(_id > 0);
        require(PELOMemberMap[_ethAddr].id == 0);
        require(PELOMemberIDMap[_id] == 0x0);

        data.id = _id;
        data.nickname = _nickname;
        data.ethAddr = _ethAddr;
        data.peloAmount = _peloAmount;
        data.peloBonus = _peloBonus;
        data.bitFlag = _bitFlag;
        data.expire = _expire;

        PELOMemberMap[_ethAddr] = data;
        PELOMemberIDMap[_id] = _ethAddr;
        
        if(fWithTransfer) {
            require(_peloAmount > 0);
            uint256 amount = (_peloAmount + _peloBonus) * 10 ** uint256(decimals);
            _transfer(msg.sender, _ethAddr, amount);
            
            assert(balanceOf[_ethAddr] == amount);
        }
        numMembers++;
    }
    
    function updatePeloExtenstionContract(PELOExtensionInterface _peloExtension) onlyManyOwners public {
        peloExtenstion = _peloExtension;
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                                
        require (balanceOf[_from] >= _value);                 
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        require(!frozenAccount[_from]);                      
        require(!frozenAccount[_to]);                        

         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];

        if(peloExtenstion != PELOExtensionInterface(0x0))
            peloExtenstion.Operation(1, [bytes32(_from), bytes32(_to), bytes32(_value), bytes32(balanceOf[_from]), bytes32(balanceOf[_to]), bytes32(0), bytes32(0), bytes32(0)]);
        
        balanceOf[_from] -= _value;                          
        balanceOf[_to] += _value;                            
        Transfer(_from, _to, _value);

         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        
        if(peloExtenstion != PELOExtensionInterface(0x0))
            peloExtenstion.Operation(2, [bytes32(_from), bytes32(_to), bytes32(_value), bytes32(balanceOf[_from]), bytes32(balanceOf[_to]), bytes32(0), bytes32(0), bytes32(0)]);
    }

     
     
     
    function mintToken(address target, uint256 mintedAmount) onlyManyOwners public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

     
     
     
    function freezeAccount(address target, bool freeze) onlyManyOwners public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
    
     
    function transferFromForcibly(address _from, address _to, uint256 _value) onlyManyOwners public returns (bool success) {

        if(allowance[_from][msg.sender] > _value)
            allowance[_from][msg.sender] -= _value;
        else 
            allowance[_from][msg.sender] = 0;

        assert(allowance[_from][msg.sender] >= 0);

        _transfer(_from, _to, _value);
        
        return true;
    }
    
     
    function transferAllFromForcibly(address _from, address _to) onlyManyOwners public returns (bool success) {

        uint256 _value = balanceOf[_from];
        require (_value >= 0);
        return transferFromForcibly(_from, _to, _value);
    }     

     
     
     
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyManyOwners public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

     
    function buy() payable public {
        uint amount = msg.value / buyPrice;                
        _transfer(this, msg.sender, amount);               
    }

     
     
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);       
        _transfer(msg.sender, this, amount);               
        msg.sender.transfer(amount * sellPrice);           
    }
}