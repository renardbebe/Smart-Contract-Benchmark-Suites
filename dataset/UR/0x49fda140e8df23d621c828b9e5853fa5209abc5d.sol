 

pragma solidity ^0.4.11;

 
 
 

 
contract KittyCore {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
  
 
    
 
contract CuddleData is Ownable {
     
    mapping (uint256 => Action) public actions;
     
    mapping (uint256 => uint256[]) typeActions;
     
    uint256[] anyActions;

     
    struct Action {
        uint256 energy;
        uint8[6] basePets;  
        uint8[6] petsAddition;  
        uint16[6] critChance;  
        uint8[6] missChance;  
        uint256 turnsAffected;  
    }
    
 
    
     
    function returnActions(uint256[8] _actions, uint256 _cuddleOwner)
      external
      view
    returns (uint256[8] energy, uint256[8] basePets, uint256[8] petsAddition,
             uint256[8] critChance, uint256[8] missChance, uint256[8] turnsAffected)
    {
        for (uint256 i = 0; i < 8; i++) {
            if (_actions[i] == 0) break;
            
            Action memory action = actions[_actions[i]];
            energy[i] = action.energy;
            basePets[i] = action.basePets[_cuddleOwner];
            petsAddition[i] = action.petsAddition[_cuddleOwner];
            critChance[i] = action.critChance[_cuddleOwner];
            missChance[i] = action.missChance[_cuddleOwner];
            turnsAffected[i] = action.turnsAffected;
        }
    }
    
     
    
     
    function getActionCount(uint256 _personality)
      external
      view
    returns (uint256 totalActions)
    {
         
         
        if (_personality == 0) return 10;
        else return 5;
    }
    
 
    
     
    function addAction(uint256 _actionId, uint256 _newEnergy, uint8[6] _newPets, uint8[6] _petAdditions,
            uint16[6] _critChance, uint8[6] _missChance, uint256 _turnsAffected, uint256 _personality)
      public  
      onlyOwner
    {
        Action memory newAction = Action(_newEnergy, _newPets, _petAdditions, _critChance, _missChance, _turnsAffected);
        actions[_actionId] = newAction;
        
        if (_personality > 0) typeActions[_personality].push(_actionId);
        else anyActions.push(_actionId);
    }
    
}

 
 
 

 
contract KittyData is Ownable {
    address public gymContract;  
    address public specialContract;  
    address public arenaContract;  
    
     
    mapping (uint256 => Kitty) public kitties;
    
     
    struct Kitty {
        uint8[2] kittyType;  
        uint32[12] actionsArray;  
        uint16 level;  
        uint16 totalBattles;  
    }
    
 
    
     
    function KittyData(address _arenaContract, address _gymContract, address _specialContract)
      public
    {
        arenaContract = _arenaContract;
        gymContract = _gymContract;
        specialContract = _specialContract;
    }
    
 
    
     
    function addKitty(uint256 _kittyId, uint256 _kittyType, uint256[5] _actions)
      external
      onlyVerified
    returns (bool success)
    {
        delete kitties[_kittyId];  
        
        kitties[_kittyId].kittyType[0] = uint8(_kittyType);
        for (uint256 i = 0; i < 5; i++) { 
            addAction(_kittyId, _actions[i], i);
        }

        return true;
    }
    
     
    function trainSpecial(uint256 _kittyId, uint256 _specialId, uint256[2] _actions, uint256[2] _slots)
      external
      onlyVerified
    returns (bool success)
    {
        kitties[_kittyId].kittyType[1] = uint8(_specialId);
        addAction(_kittyId, _actions[0], _slots[0]);
        addAction(_kittyId, _actions[1], _slots[1]);
        return true;
    }

     
    function addAction(uint256 _kittyId, uint256 _newAction, uint256 _moveSlot)
      public
      onlyVerified
    returns (bool success)
    {
        kitties[_kittyId].actionsArray[_moveSlot] = uint32(_newAction);
        return true;
    }
    

     
    function incrementBattles(uint256 _kittyId, bool _won)
      external
      onlyVerified
    returns (bool success)
    {
        if (_won) kitties[_kittyId].level++;
        kitties[_kittyId].totalBattles++;
        return true;
    }
    
 
    
     
    function fetchSlot(uint256 _kittyId, uint256 _moveSlot)
      external
      view
    returns (uint32)
    {
        return kitties[_kittyId].actionsArray[_moveSlot];
    }
    
     
    function returnKitty(uint256 _kittyId)
      external
      view
    returns (uint8[2] kittyType, uint32[12] actionsArray, uint16 level, uint16 totalBattles)
    {
        Kitty memory kitty = kitties[_kittyId];
        kittyType = kitty.kittyType;
        actionsArray = kitty.actionsArray;
        level = kitty.level;
        totalBattles = kitty.totalBattles;
    }
    
 
    
     
    function changeContracts(address _gymContract, address _specialContract, address _arenaContract)
      external
      onlyOwner
    {
        if (_gymContract != 0) gymContract = _gymContract;
        if (_specialContract != 0) specialContract = _specialContract;
        if (_arenaContract != 0) arenaContract = _arenaContract;
    }
    
 
    
     
    modifier onlyVerified()
    {
        require(msg.sender == gymContract || msg.sender == specialContract || 
                msg.sender == arenaContract);
        _;
    }
    
}

 
 
 

 
contract KittyGym is Ownable {
    KittyCore public core;
    CuddleData public cuddleData;
    CuddleCoin public token;
    KittyData public kittyData;
    address public specialGym;

    uint256 public totalKitties = 1;  
    uint256 public personalityTypes;  

    uint256 public trainFee;  
    uint256 public learnFee;  
    uint256 public rerollFee;  
    
     
    mapping (uint256 => mapping (uint256 => bool)) public kittyActions;

    event KittyTrained(uint256 indexed kittyId, uint256 indexed kittyNumber,
            uint256 indexed personality, uint256[5] learnedActions);
    event MoveLearned(uint256 indexed kittyId, uint256 indexed actionId);
    event MoveRerolled(uint256 indexed kittyId, uint256 indexed oldActionId,
                        uint256 indexed newActionId);

     
    function KittyGym(address _kittyCore, address _cuddleData, address _cuddleCoin, 
                    address _specialGym, address _kittyData)
      public 
    {
        core = KittyCore(_kittyCore);
        cuddleData = CuddleData(_cuddleData);
        token = CuddleCoin(_cuddleCoin);
        kittyData = KittyData(_kittyData);
        specialGym = _specialGym;
        
        trainFee = 0;
        learnFee = 1;
        rerollFee = 1;
        personalityTypes = 5;
    }

 

     
    function trainKitty(uint256 _kittyId)
      external
      payable
      isNotContract
    {
         
        require(core.ownerOf(_kittyId) == msg.sender);
        require(msg.value == trainFee);
        
         
        if (kittyData.fetchSlot(_kittyId, 0) > 0) {
            var (,actionsArray,,) = kittyData.returnKitty(_kittyId);
            deleteActions(_kittyId, actionsArray);  
        }

        uint256 newType = random(totalKitties * 11, 1, personalityTypes);  
        kittyActions[_kittyId][(newType * 1000) + 1] = true;
        
        uint256[2] memory newTypeActions = randomizeActions(newType, _kittyId);
        uint256[2] memory newAnyActions = randomizeActions(0, _kittyId);

        uint256[5] memory newActions;
        newActions[0] = (newType * 1000) + 1;
        newActions[1] = newTypeActions[0];
        newActions[2] = newTypeActions[1];
        newActions[3] = newAnyActions[0];
        newActions[4] = newAnyActions[1];
        
        kittyActions[_kittyId][newActions[1]] = true;
        kittyActions[_kittyId][newActions[2]] = true;
        kittyActions[_kittyId][newActions[3]] = true;
        kittyActions[_kittyId][newActions[4]] = true;
 
        assert(kittyData.addKitty(_kittyId, newType, newActions));
        KittyTrained(_kittyId, totalKitties, newType, newActions);
        totalKitties++;
        
        owner.transfer(msg.value);
    }

     
    function learnMove(uint256 _kittyId, uint256 _moveSlot)
      external
      isNotContract
    {
        require(msg.sender == core.ownerOf(_kittyId));
         
        assert(token.burn(msg.sender, learnFee));
        require(kittyData.fetchSlot(_kittyId, 0) > 0);  
        require(kittyData.fetchSlot(_kittyId, _moveSlot) == 0);  
        
        uint256 upper = cuddleData.getActionCount(0);
        uint256 actionId = unduplicate(_kittyId * 11, 999, upper, 0);  
        
        assert(!kittyActions[_kittyId][actionId]);  
        kittyActions[_kittyId][actionId] = true;
        
        assert(kittyData.addAction(_kittyId, actionId, _moveSlot));
        MoveLearned(_kittyId, actionId);
    }

     
    function reRollMove(uint256 _kittyId, uint256 _moveSlot, uint256 _typeId)
      external
      isNotContract
    {
        require(msg.sender == core.ownerOf(_kittyId));
        
         
        uint256 oldAction = kittyData.fetchSlot(_kittyId, _moveSlot);
        require(oldAction > 0);
        require(oldAction - (_typeId * 1000) < 1000);
        
         
        assert(token.burn(msg.sender, rerollFee));

        uint256 upper = cuddleData.getActionCount(_typeId);
        uint256 actionId = unduplicate(_kittyId, oldAction, upper, _typeId);

        assert(!kittyActions[_kittyId][actionId]); 
        kittyActions[_kittyId][oldAction] = false;
        kittyActions[_kittyId][actionId] = true;
        
        assert(kittyData.addAction(_kittyId, actionId, _moveSlot));
        MoveRerolled(_kittyId, oldAction, actionId);
    }
    
 
    
      
    function randomizeActions(uint256 _actionType, uint256 _kittyId)
      internal
      view
    returns (uint256[2])
    {
        uint256 upper = cuddleData.getActionCount(_actionType);
        uint256 action1 = unduplicate(_kittyId, 999, upper, _actionType);
        uint256 action2 = unduplicate(_kittyId, action1, upper, _actionType);
        return [action1,action2];
    }
    
     
    function unduplicate(uint256 _kittyId, uint256 _action1, uint256 _upper, uint256 _type)
      internal
      view
    returns (uint256 newAction)
    {
        uint256 typeBase = _type * 1000;  

        for (uint256 i = 1; i < 11; i++) {
            newAction = random(i * 666, 1, _upper) + typeBase;
            if (newAction != _action1 && !kittyActions[_kittyId][newAction]) break;
        }
        
         
        if (newAction == _action1 || kittyActions[_kittyId][newAction]) {
            for (uint256 j = 1; j < _upper + 1; j++) {
                uint256 incAction = ((newAction + j) % _upper) + 1;

                incAction += typeBase;
                if (incAction != _action1 && !kittyActions[_kittyId][incAction]) {
                    newAction = incAction;
                    break;
                }
            }
        }
    }
    
      
    function random(uint256 _rnd, uint256 _lower, uint256 _upper) 
      internal
      view
    returns (uint256) 
    {
        uint256 _seed = uint256(keccak256(keccak256(_rnd, _seed), now));
        return (_seed % _upper) + _lower;
    }
    
     
    function deleteActions(uint256 _kittyId, uint32[12] _actions)
      internal
    {
        for (uint256 i = 0; i < _actions.length; i++) {
             
            require(uint256(_actions[i]) - 50000 > 10000000);
            
            delete kittyActions[_kittyId][uint256(_actions[i])];
        }
    }
    
 
    
     
    function confirmKittyActions(uint256 _kittyId, uint256[8] _kittyActions) 
      external 
      view
    returns (bool)
    {
        for (uint256 i = 0; i < 8; i++) {
            if (!kittyActions[_kittyId][_kittyActions[i]]) return false; 
        }
        return true;
    }
    
 
    
     
    function addMoves(uint256 _kittyId, uint256[2] _moves)
      external
      onlyVerified
    returns (bool success)
    {
        kittyActions[_kittyId][_moves[0]] = true;
        kittyActions[_kittyId][_moves[1]] = true;
        return true;
    }
    
     
    function changeFees(uint256 _trainFee, uint256 _learnFee, uint256 _rerollFee)
      external
      onlyOwner
    {
        trainFee = _trainFee;
        learnFee = _learnFee;
        rerollFee = _rerollFee;
    }

     
    function changeVariables(uint256 _newTypeCount)
      external
      onlyOwner
    {
        if (_newTypeCount != 0) personalityTypes = _newTypeCount;
    }
    
     
    function changeContracts(address _newData, address _newCore, address _newToken, address _newKittyData,
                            address _newSpecialGym)
      external
      onlyOwner
    {
        if (_newData != 0) cuddleData = CuddleData(_newData);
        if (_newCore != 0) core = KittyCore(_newCore);
        if (_newToken != 0) token = CuddleCoin(_newToken);
        if (_newKittyData != 0) kittyData = KittyData(_newKittyData);
        if (_newSpecialGym != 0) specialGym = _newSpecialGym;
    }
    
 
    
     
    modifier onlyVerified()
    {
        require(msg.sender == specialGym);
        _;
    }
    
      
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
}

 
 
 

 
contract SpecialGym is Ownable {
    KittyCore public core;
    KittyData public kittyData;
    CuddleData public cuddleData;
    KittyGym public kittyGym;
    
     
    mapping (uint256 => bool) public specialKitties;
    
     
    mapping (uint256 => SpecialPersonality) public specialInfo;
    
    struct SpecialPersonality {
        uint16 population;  
        uint16 amountLeft;  
        uint256 price;  
    }
    
    event SpecialTrained(uint256 indexed kittyId, uint256 indexed specialId, 
        uint256 indexed specialRank, uint256[2] specialMoves);
    
    function SpecialGym(address _kittyCore, address _kittyData, address _cuddleData, address _kittyGym)
      public
    {
        core = KittyCore(_kittyCore);
        kittyData = KittyData(_kittyData);
        cuddleData = CuddleData(_cuddleData);
        kittyGym = KittyGym(_kittyGym);
    }
    
     
    function trainSpecial(uint256 _kittyId, uint256 _specialId, uint256[2] _slots)
      external
      payable
      isNotContract
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        
        require(msg.sender == core.ownerOf(_kittyId));
        require(kittyData.fetchSlot(_kittyId, 0) > 0);  
        require(!specialKitties[_kittyId]);
        require(msg.value == special.price);
        require(special.amountLeft > 0);

         
        uint256[2] memory randomMoves = randomizeActions(_specialId);
        
        assert(kittyData.trainSpecial(_kittyId, _specialId, randomMoves, _slots));
        assert(kittyGym.addMoves(_kittyId, randomMoves));
        
        uint256 specialRank = special.population - special.amountLeft + 1;
        SpecialTrained(_kittyId, _specialId, specialRank, randomMoves);
    
        special.amountLeft--;
        specialKitties[_kittyId] = true;
        owner.transfer(msg.value);
    }
    
 
    
      
    function randomizeActions(uint256 _specialType)
      internal
      view
    returns (uint256[2])
    {
        uint256 upper = cuddleData.getActionCount(_specialType);
        
        uint256 action1 = random(_specialType, 1, upper);
        uint256 action2 = random(action1 + 1, 1, upper);
        if (action1 == action2) {
            action2 = unduplicate(action1, upper);
        }

        uint256 typeBase = 1000 * _specialType;
        return [action1 + typeBase, action2 + typeBase];
    }
    
     
    function unduplicate(uint256 _action1, uint256 _upper)
      internal
      view
    returns (uint256)
    {
        uint256 action2;
        for (uint256 i = 1; i < 10; i++) {  
            action2 = random(action2 + i, 1, _upper);
            if (action2 != _action1) break;
        }
        
         
        if (action2 == _action1) {
            action2 = (_action1 % _upper) + 1;
        }
            
        return action2;
    }
    
      
    function random(uint256 _rnd, uint256 _lower, uint256 _upper) 
      internal
      view
    returns (uint256) 
    {
        uint256 _seed = uint256(keccak256(keccak256(_rnd, _seed), now));
        return (_seed % _upper) + _lower;
    }
    
 
    
     
    function specialsInfo(uint256 _specialId) 
      external 
      view 
    returns(uint256, uint256) 
    { 
        require(_specialId > 0); 
        return (specialInfo[_specialId].amountLeft, specialInfo[_specialId].price); 
    }
    
 
    
     
    function addSpecial(uint256 _specialId, uint256 _amountAvailable, uint256 _price)
      external
      onlyOwner
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        require(special.price == 0);
        
        special.population = uint16(_amountAvailable);
        special.amountLeft = uint16(_amountAvailable);
        special.price = _price; 
    }
    
     
    function editSpecial(uint256 _specialId, uint256 _newPrice, uint16 _amountToDestroy)
      external
      onlyOwner
    {
        SpecialPersonality storage special = specialInfo[_specialId];
        
        if (_newPrice != 0) special.price = _newPrice;
        if (_amountToDestroy != 0) {
            require(_amountToDestroy <= special.population && _amountToDestroy <= special.amountLeft);
            special.population -= _amountToDestroy;
            special.amountLeft -= _amountToDestroy;
        }
    }
    
     
    function changeContracts(address _newData, address _newCore, address _newKittyData, address _newKittyGym)
      external
      onlyOwner
    {
        if (_newData != 0) cuddleData = CuddleData(_newData);
        if (_newCore != 0) core = KittyCore(_newCore);
        if (_newKittyData != 0) kittyData = KittyData(_newKittyData);
        if (_newKittyGym != 0) kittyGym = KittyGym(_newKittyGym);
    }
    
 

      
    modifier isNotContract() {
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
}

 

contract CuddleCoin is Ownable {
    string public constant symbol = "CDL";
    string public constant name = "CuddleCoin";

    address arenaContract;  
    address vendingMachine;  
    address kittyGym;  
    
     
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 1000000 * (10 ** 18);

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping (address => uint256)) allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _amount);
    event Approval(address indexed _from, address indexed _spender, uint256 indexed _amount);
    event Mint(address indexed _to, uint256 indexed _amount);
    event Burn(address indexed _from, uint256 indexed _amount);

     
    function CuddleCoin(address _arenaContract, address _vendingMachine)
      public
    {
        balances[msg.sender] = _totalSupply;
        arenaContract = _arenaContract;
        vendingMachine = _vendingMachine;
    }

     
    function totalSupply() 
      external
      constant 
     returns (uint256) 
    {
        return _totalSupply;
    }

     
    function balanceOf(address _owner)
      external
      constant 
    returns (uint256) 
    {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _amount) 
      external
    returns (bool success)
    {
         
        require(balances[msg.sender] >= _amount);

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        Transfer(msg.sender, _to, _amount);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint _amount)
      external
    returns (bool success)
    {
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        
        Transfer(_from, _to, _amount);
        return true;
    }

     
    function approve(address _spender, uint256 _amount) 
      external
    {
        require(_amount == 0 || allowed[msg.sender][_spender] == 0);
        require(balances[msg.sender] >= _amount);
        
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
    }

     
    function allowance(address _owner, address _spender) 
      external
      constant 
    returns (uint256) 
    {
        return allowed[_owner][_spender];
    }
    
     
    function mint(address _to, uint256 _amount)
      external
      onlyMinter
    returns (bool success)
    {
        balances[_to] += _amount;
        
        Mint(_to, _amount);
        return true;
    }
    
     
    function burn(address _from, uint256 _amount)
      external
      onlyMinter
    returns (bool success)
    {
        require(balances[_from] >= _amount);
        
        balances[_from] -= _amount;
        Burn(_from, _amount);
        return true;
    }
      
     
    function changeMinters(address _arenaContract, address _vendingMachine, address _kittyGym)
      external
      onlyOwner
    returns (bool success)
    {
        if (_arenaContract != 0) arenaContract = _arenaContract;
        if (_vendingMachine != 0) vendingMachine = _vendingMachine;
        if (_kittyGym != 0) kittyGym = _kittyGym;
        
        return true;
    }
    
     
    modifier onlyMinter()
    {
        require(msg.sender == arenaContract || msg.sender == vendingMachine || msg.sender == kittyGym);
        _;
    }
}