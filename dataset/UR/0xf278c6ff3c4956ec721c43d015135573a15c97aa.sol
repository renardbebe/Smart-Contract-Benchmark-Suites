 

 

 

pragma solidity ^0.4.24;

 
 
 
 
 
contract GodMode {
     
    bool public isPaused;

     
    address public god;

     
    modifier onlyGod()
    {
        require(god == msg.sender);
        _;
    }

     
     
    modifier notPaused()
    {
        require(!isPaused);
        _;
    }

     
    event GodPaused();

     
    event GodUnpaused();

    constructor() public
    {
         
        god = msg.sender;
    }

     
     
    function godChangeGod(address _newGod) public onlyGod
    {
        god = _newGod;
    }

     
    function godPause() public onlyGod
    {
        isPaused = true;

        emit GodPaused();
    }

     
    function godUnpause() public onlyGod
    {
        isPaused = false;

        emit GodUnpaused();
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthAbstractInterface {
     
    address public king;

     
    address public wayfarer;

     
    function payTaxes() public payable;
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthReferencer is GodMode {
     
    address public kingOfEthContract;

     
    modifier onlyKingOfEthContract()
    {
        require(kingOfEthContract == msg.sender);
        _;
    }

     
     
    function godSetKingOfEthContract(address _kingOfEthContract)
        public
        onlyGod
    {
        kingOfEthContract = _kingOfEthContract;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
 
contract KingOfEthEthExchangeReferencer is GodMode {
     
    address public ethExchangeContract;

     
    modifier onlyEthExchangeContract()
    {
        require(ethExchangeContract == msg.sender);
        _;
    }

     
     
    function godSetEthExchangeContract(address _ethExchangeContract)
        public
        onlyGod
    {
        ethExchangeContract = _ethExchangeContract;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
 
contract KingOfEthResourceExchangeReferencer is GodMode {
     
    address public resourceExchangeContract;

     
    modifier onlyResourceExchangeContract()
    {
        require(resourceExchangeContract == msg.sender);
        _;
    }

     
     
    function godSetResourceExchangeContract(address _resourceExchangeContract)
        public
        onlyGod
    {
        resourceExchangeContract = _resourceExchangeContract;
    }
}

 

 

pragma solidity ^0.4.24;




 
 
 
contract KingOfEthExchangeReferencer is
      GodMode
    , KingOfEthEthExchangeReferencer
    , KingOfEthResourceExchangeReferencer
{
     
     
    modifier onlyExchangeContract()
    {
        require(
               ethExchangeContract == msg.sender
            || resourceExchangeContract == msg.sender
        );
        _;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthHousesReferencer is GodMode {
     
    address public housesContract;

     
    modifier onlyHousesContract()
    {
        require(housesContract == msg.sender);
        _;
    }

     
     
    function godSetHousesContract(address _housesContract)
        public
        onlyGod
    {
        housesContract = _housesContract;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthResourcesInterfaceReferencer is GodMode {
     
    address public interfaceContract;

     
    modifier onlyInterfaceContract()
    {
        require(interfaceContract == msg.sender);
        _;
    }

     
     
    function godSetInterfaceContract(address _interfaceContract)
        public
        onlyGod
    {
        interfaceContract = _interfaceContract;
    }
}

 

 

pragma solidity ^0.4.24;



 
 
contract ERC20Interface {
    function totalSupply() public constant returns(uint);
    function balanceOf(address _tokenOwner) public constant returns(uint balance);
    function allowance(address _tokenOwner, address _spender) public constant returns(uint remaining);
    function transfer(address _to, uint _tokens) public returns(bool success);
    function approve(address _spender, uint _tokens) public returns(bool success);
    function transferFrom(address _from, address _to, uint _tokens) public returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
contract KingOfEthResource is
      ERC20Interface
    , GodMode
    , KingOfEthResourcesInterfaceReferencer
{
     
    uint public resourceSupply;

     
    uint8 public constant decimals = 0;

     
    mapping (address => uint) holdings;

     
    mapping (address => uint) frozenHoldings;

     
    mapping (address => mapping (address => uint)) allowances;

     
     
    function totalSupply()
        public
        constant
        returns(uint)
    {
        return resourceSupply;
    }

     
     
     
    function balanceOf(address _tokenOwner)
        public
        constant
        returns(uint balance)
    {
        return holdings[_tokenOwner];
    }

     
     
     
    function frozenTokens(address _tokenOwner)
        public
        constant
        returns(uint balance)
    {
        return frozenHoldings[_tokenOwner];
    }

     
     
     
     
    function allowance(address _tokenOwner, address _spender)
        public
        constant
        returns(uint remaining)
    {
        return allowances[_tokenOwner][_spender];
    }

     
     
     
    modifier hasAvailableTokens(address _owner, uint _tokens)
    {
        require(holdings[_owner] - frozenHoldings[_owner] >= _tokens);
        _;
    }

     
     
     
    modifier hasFrozenTokens(address _owner, uint _tokens)
    {
        require(frozenHoldings[_owner] >= _tokens);
        _;
    }

     
    constructor() public
    {
         
        holdings[msg.sender] = 200;

        resourceSupply = 200;
    }

     
     
     
     
    function interfaceBurnTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasAvailableTokens(_owner, _tokens)
    {
        holdings[_owner] -= _tokens;

        resourceSupply -= _tokens;

         
        emit Transfer(_owner, 0x0, _tokens);
    }

     
     
     
    function interfaceMintTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
    {
        holdings[_owner] += _tokens;

        resourceSupply += _tokens;

         
        emit Transfer(interfaceContract, _owner, _tokens);
    }

     
     
     
    function interfaceFreezeTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasAvailableTokens(_owner, _tokens)
    {
        frozenHoldings[_owner] += _tokens;
    }

     
     
     
    function interfaceThawTokens(address _owner, uint _tokens)
        public
        onlyInterfaceContract
        hasFrozenTokens(_owner, _tokens)
    {
        frozenHoldings[_owner] -= _tokens;
    }

     
     
     
     
    function interfaceTransfer(address _from, address _to, uint _tokens)
        public
        onlyInterfaceContract
    {
        assert(holdings[_from] >= _tokens);

        holdings[_from] -= _tokens;
        holdings[_to]   += _tokens;

        emit Transfer(_from, _to, _tokens);
    }

     
     
     
     
    function interfaceFrozenTransfer(address _from, address _to, uint _tokens)
        public
        onlyInterfaceContract
        hasFrozenTokens(_from, _tokens)
    {
         
        holdings[_from]       -= _tokens;
        frozenHoldings[_from] -= _tokens;
        holdings[_to]         += _tokens;

        emit Transfer(_from, _to, _tokens);
    }

     
     
     
    function transfer(address _to, uint _tokens)
        public
        hasAvailableTokens(msg.sender, _tokens)
        returns(bool success)
    {
        holdings[_to]        += _tokens;
        holdings[msg.sender] -= _tokens;

        emit Transfer(msg.sender, _to, _tokens);

        return true;
    }

     
     
     
    function approve(address _spender, uint _tokens)
        public
        returns(bool success)
    {
        allowances[msg.sender][_spender] = _tokens;

        emit Approval(msg.sender, _spender, _tokens);

        return true;
    }

     
     
     
     
    function transferFrom(address _from, address _to, uint _tokens)
        public
        hasAvailableTokens(_from, _tokens)
        returns(bool success)
    {
        require(allowances[_from][_to] >= _tokens);

        holdings[_to]          += _tokens;
        holdings[_from]        -= _tokens;
        allowances[_from][_to] -= _tokens;

        emit Transfer(_from, _to, _tokens);

        return true;
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthResourceType {
     
    enum ResourceType {
          ETH
        , BRONZE
        , CORN
        , GOLD
        , OIL
        , ORE
        , STEEL
        , URANIUM
        , WOOD
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthRoadsReferencer is GodMode {
     
    address public roadsContract;

     
    modifier onlyRoadsContract()
    {
        require(roadsContract == msg.sender);
        _;
    }

     
     
    function godSetRoadsContract(address _roadsContract)
        public
        onlyGod
    {
        roadsContract = _roadsContract;
    }
}

 

 

pragma solidity ^0.4.24;







 
 
 
contract KingOfEthResourcesInterface is
      GodMode
    , KingOfEthExchangeReferencer
    , KingOfEthHousesReferencer
    , KingOfEthResourceType
    , KingOfEthRoadsReferencer
{
     
    uint public constant resourcesPerHouse = 3;

     
    address public bronzeContract;

     
    address public cornContract;

     
    address public goldContract;

     
    address public oilContract;

     
    address public oreContract;

     
    address public steelContract;

     
    address public uraniumContract;

     
    address public woodContract;

     
     
     
     
     
     
     
     
    constructor(
          address _bronzeContract
        , address _cornContract
        , address _goldContract
        , address _oilContract
        , address _oreContract
        , address _steelContract
        , address _uraniumContract
        , address _woodContract
    )
        public
    {
        bronzeContract  = _bronzeContract;
        cornContract    = _cornContract;
        goldContract    = _goldContract;
        oilContract     = _oilContract;
        oreContract     = _oreContract;
        steelContract   = _steelContract;
        uraniumContract = _uraniumContract;
        woodContract    = _woodContract;
    }

     
     
     
    function contractFor(ResourceType _type)
        public
        view
        returns(address)
    {
         
        require(ResourceType.ETH != _type);

        if(ResourceType.BRONZE == _type)
        {
            return bronzeContract;
        }
        else if(ResourceType.CORN == _type)
        {
            return cornContract;
        }
        else if(ResourceType.GOLD == _type)
        {
            return goldContract;
        }
        else if(ResourceType.OIL == _type)
        {
            return oilContract;
        }
        else if(ResourceType.ORE == _type)
        {
            return oreContract;
        }
        else if(ResourceType.STEEL == _type)
        {
            return steelContract;
        }
        else if(ResourceType.URANIUM == _type)
        {
            return uraniumContract;
        }
        else if(ResourceType.WOOD == _type)
        {
            return woodContract;
        }
    }

     
     
     
    function resourceType(uint _x, uint _y)
        public
        pure
        returns(ResourceType resource)
    {
        uint _seed = (_x + 7777777) ^  _y;

        if(0 == _seed % 97)
        {
          return ResourceType.URANIUM;
        }
        else if(0 == _seed % 29)
        {
          return ResourceType.OIL;
        }
        else if(0 == _seed % 23)
        {
          return ResourceType.STEEL;
        }
        else if(0 == _seed % 17)
        {
          return ResourceType.GOLD;
        }
        else if(0 == _seed % 11)
        {
          return ResourceType.BRONZE;
        }
        else if(0 == _seed % 5)
        {
          return ResourceType.WOOD;
        }
        else if(0 == _seed % 2)
        {
          return ResourceType.CORN;
        }
        else
        {
          return ResourceType.ORE;
        }
    }

     
     
     
    function lookupResourcePoints(address _player)
        public
        view
        returns(uint)
    {
        uint result = 0;

        result += KingOfEthResource(bronzeContract).balanceOf(_player);
        result += KingOfEthResource(goldContract).balanceOf(_player)    * 3;
        result += KingOfEthResource(steelContract).balanceOf(_player)   * 6;
        result += KingOfEthResource(oilContract).balanceOf(_player)     * 10;
        result += KingOfEthResource(uraniumContract).balanceOf(_player) * 44;

        return result;
    }

     
     
     
    function burnHouseCosts(uint _count, address _player)
        public
        onlyHousesContract
    {
         
        KingOfEthResource(contractFor(ResourceType.CORN)).interfaceBurnTokens(
              _player
            , 2 * _count
        );

         
        KingOfEthResource(contractFor(ResourceType.ORE)).interfaceBurnTokens(
              _player
            , 2 * _count
        );

         
        KingOfEthResource(contractFor(ResourceType.WOOD)).interfaceBurnTokens(
              _player
            , _count
        );
    }

     
     
     
    function burnUpgradeCosts(uint8 _currentLevel, address _player)
        public
        onlyHousesContract
    {
         
        require(5 > _currentLevel);

         
        burnHouseCosts(1, _player);

        if(0 == _currentLevel)
        {
             
            KingOfEthResource(contractFor(ResourceType.BRONZE)).interfaceBurnTokens(
                  _player
                , 1
            );
        }
        else if(1 == _currentLevel)
        {
             
            KingOfEthResource(contractFor(ResourceType.GOLD)).interfaceBurnTokens(
                  _player
                , 1
            );
        }
        else if(2 == _currentLevel)
        {
             
            KingOfEthResource(contractFor(ResourceType.STEEL)).interfaceBurnTokens(
                  _player
                , 1
            );
        }
        else if(3 == _currentLevel)
        {
             
            KingOfEthResource(contractFor(ResourceType.OIL)).interfaceBurnTokens(
                  _player
                , 1
            );
        }
        else if(4 == _currentLevel)
        {
             
            KingOfEthResource(contractFor(ResourceType.URANIUM)).interfaceBurnTokens(
                  _player
                , 1
            );
        }
    }

     
     
     
     
     
     
    function distributeResources(address _owner, uint _x, uint _y, uint8 _level)
        public
        onlyHousesContract
    {
         
        uint _count = resourcesPerHouse * uint(_level + 1);

         
        KingOfEthResource(contractFor(resourceType(_x - 1, _y - 1))).interfaceMintTokens(
            _owner
          , _count
        );

         
        KingOfEthResource(contractFor(resourceType(_x, _y - 1))).interfaceMintTokens(
            _owner
          , _count
        );

         
        KingOfEthResource(contractFor(resourceType(_x, _y))).interfaceMintTokens(
            _owner
          , _count
        );

         
        KingOfEthResource(contractFor(resourceType(_x - 1, _y))).interfaceMintTokens(
            _owner
          , _count
        );
    }

     
     
     
    function burnRoadCosts(uint _length, address _player)
        public
        onlyRoadsContract
    {
         
        KingOfEthResource(cornContract).interfaceBurnTokens(
              _player
            , _length
        );

         
        KingOfEthResource(oreContract).interfaceBurnTokens(
              _player
            , _length
        );
    }

     
     
     
     
    function exchangeFreezeTokens(ResourceType _type, address _owner, uint _tokens)
        public
        onlyExchangeContract
    {
        KingOfEthResource(contractFor(_type)).interfaceFreezeTokens(_owner, _tokens);
    }

     
     
     
     
    function exchangeThawTokens(ResourceType _type, address _owner, uint _tokens)
        public
        onlyExchangeContract
    {
        KingOfEthResource(contractFor(_type)).interfaceThawTokens(_owner, _tokens);
    }

     
     
     
     
     
    function exchangeTransfer(ResourceType _type, address _from, address _to, uint _tokens)
        public
        onlyExchangeContract
    {
        KingOfEthResource(contractFor(_type)).interfaceTransfer(_from, _to, _tokens);
    }

     
     
     
     
     
    function exchangeFrozenTransfer(ResourceType _type, address _from, address _to, uint _tokens)
        public
        onlyExchangeContract
    {
        KingOfEthResource(contractFor(_type)).interfaceFrozenTransfer(_from, _to, _tokens);
    }
}

 

 

pragma solidity ^0.4.24;







 
 
 
contract KingOfEthEthExchange is
      GodMode
    , KingOfEthReferencer
    , KingOfEthResourcesInterfaceReferencer
    , KingOfEthResourceType
{
     
    struct Trade {
         
        address creator;

         
        ResourceType resource;

         
        ResourceType tradingFor;

         
        uint amountRemaining;

         
         
        uint price;
    }

     
    uint public constant priceDecimals = 6;

     
    uint public constant taxDivisor = 25;

     
    uint public nextTradeId;

     
    mapping (uint => Trade) trades;

     
    event EthTradeCreated(
          uint tradeId
        , ResourceType resource
        , ResourceType tradingFor
        , uint amount
        , uint price
        , address creator
    );

     
    event EthTradeFilled(
          uint tradeId
        , ResourceType resource
        , ResourceType tradingFor
        , uint amount
        , uint price
        , address creator
        , address filler
    );

     
    event EthTradeCancelled(
          uint tradeId
        , ResourceType resource
        , ResourceType tradingFor
        , uint amount
        , address creator
    );

     
     
     
    constructor(
          address _kingOfEthContract
        , address _interfaceContract
    )
        public
    {
        kingOfEthContract = _kingOfEthContract;
        interfaceContract = _interfaceContract;
    }

     
     
     
     
     
     
     
    function createTrade(
          ResourceType _resource
        , ResourceType _tradingFor
        , uint _amount
        , uint _price
    )
        public
        payable
        returns(uint)
    {
         
        require(
               ResourceType.ETH == _resource
            || ResourceType.ETH == _tradingFor
        );

         
        require(_resource != _tradingFor);

         
        require(0 < _amount);

         
        require(0 < _price);

         
        if(ResourceType.ETH == _resource)
        {
             
            uint _size = _amount * _price;

             
            require(_amount == _size / _price);

             
            _size /= 10 ** priceDecimals;

             
            require(0 == _size % 1 ether);

             
            require(_amount == msg.value);
        }
         
        else
        {
             
            KingOfEthResourcesInterface(interfaceContract).exchangeFreezeTokens(
                  _resource
                , msg.sender
                , _amount
            );
        }

         
        trades[nextTradeId] = Trade(
              msg.sender
            , _resource
            , _tradingFor
            , _amount
            , _price
        );

        emit EthTradeCreated(
              nextTradeId
            , _resource
            , _tradingFor
            , _amount
            , _price
            , msg.sender
        );

         
        return nextTradeId++;
    }

     
     
     
    function fillTrade(uint _tradeId, uint _amount) public payable
    {
         
        require(0 < _amount);

         
        Trade storage _trade = trades[_tradeId];

         
        require(_trade.amountRemaining >= _amount);

         
        _trade.amountRemaining -= _amount;

         
        uint _size;

         
        uint _taxCut;

         
        if(ResourceType.ETH == _trade.resource)
        {
             
            _size = _trade.price * _amount;

             
            require(_size / _trade.price == _amount);

             
            _size /= 10 ** priceDecimals;

             
            require(0 == _size % 1 ether);

             
            _size /= 1 ether;

             
            require(0 == msg.value);

             
            _taxCut = _amount / taxDivisor;

             
            msg.sender.transfer(_amount - _taxCut);

             
            KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(_taxCut)();

             
            KingOfEthResourcesInterface(interfaceContract).exchangeTransfer(
                  _trade.tradingFor
                , msg.sender
                , _trade.creator
                , _size
            );
        }
         
        else
        {
             
            _size = _trade.price * _amount;

             
            require(_size / _trade.price == _amount);

             
            uint _temp = _size * 1 ether;

             
            require(_size == _temp / 1 ether);

             
            _size = _temp / (10 ** priceDecimals);

             
            require(_size == msg.value);

             
            _taxCut = msg.value / taxDivisor;

             
            _trade.creator.transfer(msg.value - _taxCut);

             
            KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(_taxCut)();

             
            KingOfEthResourcesInterface(interfaceContract).exchangeFrozenTransfer(
                  _trade.resource
                , _trade.creator
                , msg.sender
                , _amount
            );
        }

        emit EthTradeFilled(
              _tradeId
            , _trade.resource
            , _trade.tradingFor
            , _amount
            , _trade.price
            , _trade.creator
            , msg.sender
        );
    }

     
     
    function cancelTrade(uint _tradeId) public
    {
         
        Trade storage _trade = trades[_tradeId];

         
        require(_trade.creator == msg.sender);

         
        uint _amountRemaining = _trade.amountRemaining;

         
         
        _trade.amountRemaining = 0;

         
        if(ResourceType.ETH == _trade.resource)
        {
             
            msg.sender.transfer(_amountRemaining);
        }
         
        else
        {
             
            KingOfEthResourcesInterface(interfaceContract).exchangeThawTokens(
                  _trade.resource
                , msg.sender
                , _amountRemaining
            );
        }

        emit EthTradeCancelled(
              _tradeId
            , _trade.resource
            , _trade.tradingFor
            , _amountRemaining
            , msg.sender
        );
    }
}