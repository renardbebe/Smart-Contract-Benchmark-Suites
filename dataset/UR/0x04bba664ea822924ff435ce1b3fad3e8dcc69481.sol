 

 

 

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

 
 
 
contract KingOfEthAuctionsAbstractInterface {
     
     
     
     
    function existingAuction(uint _x, uint _y) public view returns(bool);
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthBlindAuctionsReferencer is GodMode {
     
    address public blindAuctionsContract;

     
    modifier onlyBlindAuctionsContract()
    {
        require(blindAuctionsContract == msg.sender);
        _;
    }

     
     
     
    function godSetBlindAuctionsContract(address _blindAuctionsContract)
        public
        onlyGod
    {
        blindAuctionsContract = _blindAuctionsContract;
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthOpenAuctionsReferencer is GodMode {
     
    address public openAuctionsContract;

     
    modifier onlyOpenAuctionsContract()
    {
        require(openAuctionsContract == msg.sender);
        _;
    }

     
    function godSetOpenAuctionsContract(address _openAuctionsContract)
        public
        onlyGod
    {
        openAuctionsContract = _openAuctionsContract;
    }
}

 

 

pragma solidity ^0.4.24;



 
 
 
contract KingOfEthAuctionsReferencer is
      KingOfEthBlindAuctionsReferencer
    , KingOfEthOpenAuctionsReferencer
{
     
    modifier onlyAuctionsContract()
    {
        require(blindAuctionsContract == msg.sender
             || openAuctionsContract == msg.sender);
        _;
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





 
 
 
contract KingOfEthBoard is
      GodMode
    , KingOfEthAuctionsReferencer
    , KingOfEthReferencer
{
     
    uint public boundX1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffef;

     
    uint public boundY1 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffef;

     
    uint public boundX2 = 0x800000000000000000000000000000000000000000000000000000000000000f;

     
    uint public boundY2 = 0x800000000000000000000000000000000000000000000000000000000000000f;

     
     
     
    uint public constant auctionsAvailableDivisor = 10;

     
    uint public constant kingTimeBetweenIncrease = 2 weeks;

     
    uint public constant wayfarerTimeBetweenIncrease = 3 weeks;

     
     
    uint public constant plebTimeBetweenIncrease = 4 weeks;

     
    uint public lastIncreaseTime;

     
    uint8 public nextIncreaseDirection;

     
     
    uint public auctionsRemaining;

    constructor() public
    {
         
        isPaused = true;

         
        setAuctionsAvailableForBounds();
    }

     
    event BoardSizeIncreased(
          address initiator
        , uint newBoundX1
        , uint newBoundY1
        , uint newBoundX2
        , uint newBoundY2
        , uint lastIncreaseTime
        , uint nextIncreaseDirection
        , uint auctionsRemaining
    );

     
    modifier onlyKing()
    {
        require(KingOfEthAbstractInterface(kingOfEthContract).king() == msg.sender);
        _;
    }

     
    modifier onlyWayfarer()
    {
        require(KingOfEthAbstractInterface(kingOfEthContract).wayfarer() == msg.sender);
        _;
    }

     
    function setAuctionsAvailableForBounds() private
    {
        uint boundDiffX = boundX2 - boundX1;
        uint boundDiffY = boundY2 - boundY1;

        auctionsRemaining = boundDiffX * boundDiffY / 2 / auctionsAvailableDivisor;
    }

     
     
    function increaseBoard() private
    {
         
        uint _increaseLength;

         
        if(0 == nextIncreaseDirection)
        {
            _increaseLength = boundX2 - boundX1;
            uint _updatedX2 = boundX2 + _increaseLength;

             
            if(_updatedX2 <= boundX2 || _updatedX2 <= _increaseLength)
            {
                boundX2 = ~uint(0);
            }
            else
            {
                boundX2 = _updatedX2;
            }
        }
         
        else if(1 == nextIncreaseDirection)
        {
            _increaseLength = boundY2 - boundY1;
            uint _updatedY2 = boundY2 + _increaseLength;

             
            if(_updatedY2 <= boundY2 || _updatedY2 <= _increaseLength)
            {
                boundY2 = ~uint(0);
            }
            else
            {
                boundY2 = _updatedY2;
            }
        }
         
        else if(2 == nextIncreaseDirection)
        {
            _increaseLength = boundX2 - boundX1;

             
            if(boundX1 <= _increaseLength)
            {
                boundX1 = 0;
            }
            else
            {
                boundX1 -= _increaseLength;
            }
        }
         
        else if(3 == nextIncreaseDirection)
        {
            _increaseLength = boundY2 - boundY1;

             
            if(boundY1 <= _increaseLength)
            {
                boundY1 = 0;
            }
            else
            {
                boundY1 -= _increaseLength;
            }
        }

         
        lastIncreaseTime = now;

         
        nextIncreaseDirection = (nextIncreaseDirection + 1) % 4;

         
        setAuctionsAvailableForBounds();

        emit BoardSizeIncreased(
              msg.sender
            , boundX1
            , boundY1
            , boundX2
            , boundY2
            , now
            , nextIncreaseDirection
            , auctionsRemaining
        );
    }

     
    function godStartGame() public onlyGod
    {
         
        lastIncreaseTime = now;

         
        godUnpause();
    }

     
     
    function auctionsDecrementAuctionsRemaining()
        public
        onlyAuctionsContract
    {
        auctionsRemaining -= 1;
    }

     
     
     
    function auctionsIncrementAuctionsRemaining()
        public
        onlyAuctionsContract
    {
        auctionsRemaining += 1;
    }

     
    function kingIncreaseBoard()
        public
        onlyKing
    {
         
        require(lastIncreaseTime + kingTimeBetweenIncrease < now);

        increaseBoard();
    }

     
    function wayfarerIncreaseBoard()
        public
        onlyWayfarer
    {
         
        require(lastIncreaseTime + wayfarerTimeBetweenIncrease < now);

        increaseBoard();
    }

     
    function plebIncreaseBoard() public
    {
         
        require(lastIncreaseTime + plebTimeBetweenIncrease < now);

        increaseBoard();
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthBoardReferencer is GodMode {
     
    address public boardContract;

     
    modifier onlyBoardContract()
    {
        require(boardContract == msg.sender);
        _;
    }

     
     
    function godSetBoardContract(address _boardContract)
        public
        onlyGod
    {
        boardContract = _boardContract;
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthHousesAbstractInterface {
     
     
     
     
    function ownerOf(uint _x, uint _y) public view returns(address);

     
     
     
     
    function level(uint _x, uint _y) public view returns(uint8);

     
     
     
     
    function auctionsSetOwner(uint _x, uint _y, address _owner) public;

     
     
     
     
     
    function houseRealtyTransferOwnership(
          uint _x
        , uint _y
        , address _from
        , address _to
    ) public;
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






 
 
 
contract KingOfEthHouseRealty is
      GodMode
    , KingOfEthHousesReferencer
    , KingOfEthReferencer
{
     
     
    uint public constant taxDivisor = 25;

     
     
    mapping (uint => mapping (uint => uint)) housePrices;

     
    event HouseForSale(
          uint x
        , uint y
        , address owner
        , uint amount
    );

     
    event HousePriceChanged(uint x, uint y, uint amount);

     
    event HouseSold(
          uint x
        , uint y
        , address from
        , address to
        , uint amount
        , uint8 level
    );

     
    event HouseSaleCancelled(
          uint x
        , uint y
        , address owner
    );

     
     
     
    modifier onlyHouseOwner(uint _x, uint _y)
    {
        require(KingOfEthHousesAbstractInterface(housesContract).ownerOf(_x, _y) == msg.sender);
        _;
    }

     
     
     
     
    modifier noExistingHouseSale(uint _x, uint _y)
    {
        require(0 == housePrices[_x][_y]);
        _;
    }

     
     
     
     
    modifier existingHouseSale(uint _x, uint _y)
    {
        require(0 != housePrices[_x][_y]);
        _;
    }

     
    constructor(address _kingOfEthContract) public
    {
        kingOfEthContract = _kingOfEthContract;
    }

     
     
     
     
    function housesCancelHouseSale(uint _x, uint _y)
        public
        onlyHousesContract
    {
         
        if(0 != housePrices[_x][_y])
        {
             
            housePrices[_x][_y] = 0;

            emit HouseSaleCancelled(_x, _y, msg.sender);
        }
    }

     
     
     
     
     
    function startHouseSale(uint _x, uint _y, uint _askingPrice)
        public
        notPaused
        onlyHouseOwner(_x, _y)
        noExistingHouseSale(_x, _y)
    {
         
        require(0 != _askingPrice);

         
        housePrices[_x][_y] = _askingPrice;

        emit HouseForSale(_x, _y, msg.sender, _askingPrice);
    }

     
     
     
     
     
    function changeHousePrice(uint _x, uint _y, uint _askingPrice)
        public
        notPaused
        onlyHouseOwner(_x, _y)
        existingHouseSale(_x, _y)
    {
         
        require(0 != _askingPrice);

         
        housePrices[_x][_y] = _askingPrice;

        emit HousePriceChanged(_x, _y, _askingPrice);
    }

     
     
     
    function purchaseHouse(uint _x, uint _y)
        public
        payable
        notPaused
        existingHouseSale(_x, _y)
    {
         
        require(housePrices[_x][_y] == msg.value);

         
        housePrices[_x][_y] = 0;

         
        uint taxCut = msg.value / taxDivisor;

         
        KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(taxCut)();

        KingOfEthHousesAbstractInterface _housesContract = KingOfEthHousesAbstractInterface(housesContract);

         
        address _oldOwner = _housesContract.ownerOf(_x, _y);

         
        _housesContract.houseRealtyTransferOwnership(
              _x
            , _y
            , _oldOwner
            , msg.sender
        );

         
        _oldOwner.transfer(msg.value - taxCut);

        emit HouseSold(
              _x
            , _y
            , _oldOwner
            , msg.sender
            , msg.value
            , _housesContract.level(_x, _y)
        );
    }

     
     
     
    function cancelHouseSale(uint _x, uint _y)
        public
        notPaused
        onlyHouseOwner(_x, _y)
        existingHouseSale(_x, _y)
    {
         
        housePrices[_x][_y] = 0;

        emit HouseSaleCancelled(_x, _y, msg.sender);
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthHouseRealtyReferencer is GodMode {
     
    address public houseRealtyContract;

     
    modifier onlyHouseRealtyContract()
    {
        require(houseRealtyContract == msg.sender);
        _;
    }

     
     
    function godSetHouseRealtyContract(address _houseRealtyContract)
        public
        onlyGod
    {
        houseRealtyContract = _houseRealtyContract;
    }
}

 

 

pragma solidity ^0.4.24;

 
 
 
contract KingOfEthRoadsAbstractInterface {
     
     
     
     
     
     
    function ownerOf(uint _x, uint _y, uint8 _direction) public view returns(address);

     
     
     
     
     
     
    function roadRealtyTransferOwnership(
          uint _x
        , uint _y
        , uint8 _direction
        , address _from
        , address _to
    ) public;
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














 
 
 
contract KingOfEthHouses is
      GodMode
    , KingOfEthAuctionsReferencer
    , KingOfEthBoardReferencer
    , KingOfEthHouseRealtyReferencer
    , KingOfEthHousesAbstractInterface
    , KingOfEthReferencer
    , KingOfEthRoadsReferencer
    , KingOfEthResourcesInterfaceReferencer
{
     
    uint public houseCost = 0.001 ether;

     
    struct LocationInfo {
         
        address owner;

         
        uint8 level;
    }

     
    mapping (uint => mapping (uint => LocationInfo)) locationInfo;

     
    mapping (address => uint) pointCounts;

     
     
     
     
     
     
     
     
    constructor(
          address _blindAuctionsContract
        , address _boardContract
        , address _kingOfEthContract
        , address _houseRealtyContract
        , address _openAuctionsContract
        , address _roadsContract
        , address _interfaceContract
    )
        public
    {
        blindAuctionsContract = _blindAuctionsContract;
        boardContract         = _boardContract;
        kingOfEthContract     = _kingOfEthContract;
        houseRealtyContract   = _houseRealtyContract;
        openAuctionsContract  = _openAuctionsContract;
        roadsContract         = _roadsContract;
        interfaceContract     = _interfaceContract;
    }

     
    event NewHouses(address owner, uint[] locations);

     
    event SentHouse(uint x, uint y, address from, address to, uint8 level);

     
    event UpgradedHouse(uint x, uint y, address owner, uint8 newLevel);

     
     
     
     
    function ownerOf(uint _x, uint _y) public view returns(address)
    {
        return locationInfo[_x][_y].owner;
    }

     
     
     
     
    function level(uint _x, uint _y) public view returns(uint8)
    {
        return locationInfo[_x][_y].level;
    }

     
     
     
    function numberOfPoints(address _player) public view returns(uint)
    {
        return pointCounts[_player];
    }

     
     
     
    function buildHouseInner(uint _x, uint _y) private
    {
         
        LocationInfo storage _locationInfo = locationInfo[_x][_y];

        KingOfEthBoard _boardContract = KingOfEthBoard(boardContract);

         
        require(_boardContract.boundX1() <= _x);
        require(_boardContract.boundY1() <= _y);
        require(_boardContract.boundX2() > _x);
        require(_boardContract.boundY2() > _y);

         
        require(0x0 == _locationInfo.owner);

        KingOfEthRoadsAbstractInterface _roadsContract = KingOfEthRoadsAbstractInterface(roadsContract);

         
         
        require(
                _roadsContract.ownerOf(_x, _y, 0) == msg.sender
             || _roadsContract.ownerOf(_x, _y, 1) == msg.sender
             || _roadsContract.ownerOf(_x - 1, _y, 0) == msg.sender
             || _roadsContract.ownerOf(_x, _y - 1, 1) == msg.sender
        );

         
        require(!KingOfEthAuctionsAbstractInterface(blindAuctionsContract).existingAuction(_x, _y));

         
        require(!KingOfEthAuctionsAbstractInterface(openAuctionsContract).existingAuction(_x, _y));

         
        _locationInfo.owner = msg.sender;

         
        ++pointCounts[msg.sender];

         
        KingOfEthResourcesInterface(interfaceContract).distributeResources(
              msg.sender
            , _x
            , _y
            , 0  
        );
    }

     
     
    function godChangeHouseCost(uint _newHouseCost)
        public
        onlyGod
    {
        houseCost = _newHouseCost;
    }

     
     
     
     
    function auctionsSetOwner(uint _x, uint _y, address _owner)
        public
        onlyAuctionsContract
    {
         
        LocationInfo storage _locationInfo = locationInfo[_x][_y];

         
         
         
         
        require(0x0 == _locationInfo.owner);

         
        _locationInfo.owner = _owner;

         
        ++pointCounts[_owner];

         
        KingOfEthResourcesInterface(interfaceContract).distributeResources(
              _owner
            , _x
            , _y
            , 0  
        );

         
        uint[] memory _locations = new uint[](2);
        _locations[0] = _x;
        _locations[1] = _y;

        emit NewHouses(_owner, _locations);
    }

     
     
     
     
     
    function houseRealtyTransferOwnership(
          uint _x
        , uint _y
        , address _from
        , address _to
    )
        public
        onlyHouseRealtyContract
    {
         
        LocationInfo storage _locationInfo = locationInfo[_x][_y];

         
        assert(_locationInfo.owner == _from);

         
        _locationInfo.owner = _to;

         
        uint _points = _locationInfo.level + 1;

         
        pointCounts[_from] -= _points;
        pointCounts[_to]   += _points;
    }

     
     
     
     
    function buildHouses(uint[] _locations)
        public
        payable
    {
         
        require(0 == _locations.length % 2);

        uint _count = _locations.length / 2;

         
        require(houseCost * _count == msg.value);

         
        KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(msg.value)();

         
        KingOfEthResourcesInterface(interfaceContract).burnHouseCosts(
              _count
            , msg.sender
        );

         
        for(uint i = 0; i < _locations.length; i += 2)
        {
            buildHouseInner(_locations[i], _locations[i + 1]);
        }

        emit NewHouses(msg.sender, _locations);
    }

     
     
     
     
    function sendHouse(uint _x, uint _y, address _to) public
    {
         
        LocationInfo storage _locationInfo = locationInfo[_x][_y];

         
        require(_locationInfo.owner == msg.sender);

         
        _locationInfo.owner = _to;

         
        uint _points = _locationInfo.level + 1;

         
        pointCounts[msg.sender] -= _points;
        pointCounts[_to]        += _points;

         
        KingOfEthHouseRealty(houseRealtyContract).housesCancelHouseSale(_x, _y);

        emit SentHouse(_x, _y, msg.sender, _to, _locationInfo.level);
    }

     
     
     
    function upgradeHouse(uint _x, uint _y) public payable
    {
         
        LocationInfo storage _locationInfo = locationInfo[_x][_y];

         
        require(_locationInfo.owner == msg.sender);

         
        require(houseCost == msg.value);

         
        KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(msg.value)();

         
        KingOfEthResourcesInterface(interfaceContract).burnUpgradeCosts(
              _locationInfo.level
            , msg.sender
        );

         
        ++locationInfo[_x][_y].level;

         
        ++pointCounts[msg.sender];

         
        KingOfEthResourcesInterface(interfaceContract).distributeResources(
              msg.sender
            , _x
            , _y
            , _locationInfo.level
        );

        emit UpgradedHouse(_x, _y, msg.sender, _locationInfo.level);
    }
}

 

 

pragma solidity ^0.4.24;






 
 
 
contract KingOfEthRoadRealty is
      GodMode
    , KingOfEthReferencer
    , KingOfEthRoadsReferencer
{
     
     
    uint public constant taxDivisor = 25;

     
     
    mapping (uint => mapping (uint => uint[2])) roadPrices;

     
    event RoadForSale(
          uint x
        , uint y
        , uint8 direction
        , address owner
        , uint amount
    );

     
    event RoadPriceChanged(
          uint x
        , uint y
        , uint8 direction
        , uint amount
    );

     
    event RoadSold(
          uint x
        , uint y
        , uint8 direction
        , address from
        , address to
        , uint amount
    );

     
    event RoadSaleCancelled(
          uint x
        , uint y
        , uint8 direction
        , address owner
    );

     
     
     
     
    modifier onlyRoadOwner(uint _x, uint _y, uint8 _direction)
    {
        require(KingOfEthRoadsAbstractInterface(roadsContract).ownerOf(_x, _y, _direction) == msg.sender);
        _;
    }

     
     
     
     
     
    modifier noExistingRoadSale(uint _x, uint _y, uint8 _direction)
    {
        require(0 == roadPrices[_x][_y][_direction]);
        _;
    }

     
     
     
     
     
    modifier existingRoadSale(uint _x, uint _y, uint8 _direction)
    {
        require(0 != roadPrices[_x][_y][_direction]);
        _;
    }

     
    constructor(address _kingOfEthContract) public
    {
        kingOfEthContract = _kingOfEthContract;
    }

     
     
     
     
     
    function roadsCancelRoadSale(uint _x, uint _y, uint8 _direction)
        public
        onlyRoadsContract
    {
         
        if(0 != roadPrices[_x][_y][_direction])
        {
             
            roadPrices[_x][_y][_direction] = 0;

            emit RoadSaleCancelled(_x, _y, _direction, msg.sender);
        }
    }

     
     
     
     
     
     
    function startRoadSale(
          uint _x
        , uint _y
        , uint8 _direction
        , uint _askingPrice
    )
        public
        notPaused
        onlyRoadOwner(_x, _y, _direction)
        noExistingRoadSale(_x, _y, _direction)
    {
         
        require(0 != _askingPrice);

         
        roadPrices[_x][_y][_direction] = _askingPrice;

        emit RoadForSale(_x, _y, _direction, msg.sender, _askingPrice);
    }

     
     
     
     
     
     
    function changeRoadPrice(
          uint _x
        , uint _y
        , uint8 _direction
        , uint _askingPrice
    )
        public
        notPaused
        onlyRoadOwner(_x, _y, _direction)
        existingRoadSale(_x, _y, _direction)
    {
         
        require(0 != _askingPrice);

         
        roadPrices[_x][_y][_direction] = _askingPrice;

        emit RoadPriceChanged(_x, _y, _direction, _askingPrice);
    }

     
     
     
     
    function purchaseRoad(uint _x, uint _y, uint8 _direction)
        public
        payable
        notPaused
        existingRoadSale(_x, _y, _direction)
    {
         
        require(roadPrices[_x][_y][_direction] == msg.value);

         
        roadPrices[_x][_y][_direction] = 0;

         
        uint taxCut = msg.value / taxDivisor;

         
        KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(taxCut)();

        KingOfEthRoadsAbstractInterface _roadsContract = KingOfEthRoadsAbstractInterface(roadsContract);

         
        address _oldOwner = _roadsContract.ownerOf(_x, _y, _direction);

         
        _roadsContract.roadRealtyTransferOwnership(
              _x
            , _y
            , _direction
            , _oldOwner
            , msg.sender
        );

         
        _oldOwner.transfer(msg.value - taxCut);

        emit RoadSold(
              _x
            , _y
            , _direction
            , _oldOwner
            , msg.sender
            , msg.value
        );
    }

     
     
     
     
    function cancelRoadSale(uint _x, uint _y, uint8 _direction)
        public
        notPaused
        onlyRoadOwner(_x, _y, _direction)
        existingRoadSale(_x, _y, _direction)
    {
         
        roadPrices[_x][_y][_direction] = 0;

        emit RoadSaleCancelled(_x, _y, _direction, msg.sender);
    }
}

 

 

pragma solidity ^0.4.24;


 
 
 
contract KingOfEthRoadRealtyReferencer is GodMode {
     
    address public roadRealtyContract;

     
    modifier onlyRoadRealtyContract()
    {
        require(roadRealtyContract == msg.sender);
        _;
    }

     
     
    function godSetRoadRealtyContract(address _roadRealtyContract)
        public
        onlyGod
    {
        roadRealtyContract = _roadRealtyContract;
    }
}

 

 

pragma solidity ^0.4.24;













 
 
 
contract KingOfEthRoads is
      GodMode
    , KingOfEthBoardReferencer
    , KingOfEthHousesReferencer
    , KingOfEthReferencer
    , KingOfEthResourcesInterfaceReferencer
    , KingOfEthRoadRealtyReferencer
    , KingOfEthRoadsAbstractInterface
{
     
    uint public roadCost = 0.0002 ether;

     
    mapping (uint => mapping (uint => address[2])) owners;

     
    mapping (address => uint) roadCounts;

     
     
     
     
     
    constructor(
          address _boardContract
        , address _roadRealtyContract
        , address _kingOfEthContract
        , address _interfaceContract
    )
        public
    {
        boardContract      = _boardContract;
        roadRealtyContract = _roadRealtyContract;
        kingOfEthContract  = _kingOfEthContract;
        interfaceContract  = _interfaceContract;
    }

     
    event NewRoads(
          address owner
        , uint x
        , uint y
        , uint8 direction
        , uint length
    );

     
    event SentRoad(
          uint x
        , uint y
        , uint direction
        , address from
        , address to
    );

     
     
     
     
     
     
    function ownerOf(uint _x, uint _y, uint8 _direction)
        public
        view
        returns(address)
    {
         
        require(2 > _direction);

        return owners[_x][_y][_direction];
    }

     
     
     
    function numberOfRoads(address _player) public view returns(uint)
    {
        return roadCounts[_player];
    }

     
     
     
     
    modifier onlyRoadOwner(uint _x, uint _y, uint8 _direction)
    {
        require(owners[_x][_y][_direction] == msg.sender);
        _;
    }

     
     
     
     
    function buildRight(uint _x, uint _y, uint _length) private
    {
         
        require(0x0 == owners[_x][_y][0]);

        KingOfEthHousesAbstractInterface _housesContract = KingOfEthHousesAbstractInterface(housesContract);

         
         
         
        address _houseOwner = _housesContract.ownerOf(_x, _y);
        require(_houseOwner == msg.sender || (0x0 == _houseOwner && (
               owners[_x][_y][1] == msg.sender
            || owners[_x - 1][_y][0] == msg.sender
            || owners[_x][_y - 1][1] == msg.sender
        )));

         
        owners[_x][_y][0] = msg.sender;

        for(uint _i = 1; _i < _length; ++_i)
        {
             
            require(0x0 == owners[_x + _i][_y][0]);

             
             
            require(
                   _housesContract.ownerOf(_x + _i, _y) == 0x0
                || _housesContract.ownerOf(_x + _i, _y) == msg.sender
            );

             
            owners[_x + _i][_y][0] = msg.sender;
        }
    }

     
     
     
     
    function buildDown(uint _x, uint _y, uint _length) private
    {
         
        require(0x0 == owners[_x][_y][1]);

        KingOfEthHousesAbstractInterface _housesContract = KingOfEthHousesAbstractInterface(housesContract);

         
         
         
        address _houseOwner = _housesContract.ownerOf(_x, _y);
        require(_houseOwner == msg.sender || (0x0 == _houseOwner && (
               owners[_x][_y][0] == msg.sender
            || owners[_x - 1][_y][0] == msg.sender
            || owners[_x][_y - 1][1] == msg.sender
        )));

         
        owners[_x][_y][1] = msg.sender;

        for(uint _i = 1; _i < _length; ++_i)
        {
             
            require(0x0 == owners[_x][_y + _i][1]);

             
             
            require(
                   _housesContract.ownerOf(_x, _y + _i) == 0x0
                || _housesContract.ownerOf(_x, _y + _i) == msg.sender
            );

             
            owners[_x][_y + _i][1] = msg.sender;
        }
    }

     
     
     
     
    function buildLeft(uint _x, uint _y, uint _length) private
    {
         
        require(0x0 == owners[_x - 1][_y][0]);

        KingOfEthHousesAbstractInterface _housesContract = KingOfEthHousesAbstractInterface(housesContract);

         
         
         
        address _houseOwner = _housesContract.ownerOf(_x, _y);
        require(_houseOwner == msg.sender || (0x0 == _houseOwner && (
               owners[_x][_y][0] == msg.sender
            || owners[_x][_y][1] == msg.sender
            || owners[_x][_y - 1][1] == msg.sender
        )));

         
        owners[_x - 1][_y][0] = msg.sender;

        for(uint _i = 1; _i < _length; ++_i)
        {
             
            require(0x0 == owners[_x - _i - 1][_y][0]);

             
             
            require(
                   _housesContract.ownerOf(_x - _i, _y) == 0x0
                || _housesContract.ownerOf(_x - _i, _y) == msg.sender
            );

             
            owners[_x - _i - 1][_y][0] = msg.sender;
        }
    }

     
     
     
     
    function buildUp(uint _x, uint _y, uint _length) private
    {
         
        require(0x0 == owners[_x][_y - 1][1]);

        KingOfEthHousesAbstractInterface _housesContract = KingOfEthHousesAbstractInterface(housesContract);

         
         
         
        address _houseOwner = _housesContract.ownerOf(_x, _y);
        require(_houseOwner == msg.sender || (0x0 == _houseOwner && (
               owners[_x][_y][0] == msg.sender
            || owners[_x][_y][1] == msg.sender
            || owners[_x - 1][_y][0] == msg.sender
        )));

         
        owners[_x][_y - 1][1] = msg.sender;

        for(uint _i = 1; _i < _length; ++_i)
        {
             
            require(0x0 == owners[_x][_y - _i - 1][1]);

             
             
            require(
                   _housesContract.ownerOf(_x, _y - _i) == 0x0
                || _housesContract.ownerOf(_x, _y - _i) == msg.sender
            );

             
            owners[_x][_y - _i - 1][1] = msg.sender;
        }
    }

     
     
    function godChangeRoadCost(uint _newRoadCost)
        public
        onlyGod
    {
        roadCost = _newRoadCost;
    }

     
     
     
     
     
     
    function roadRealtyTransferOwnership(
          uint _x
        , uint _y
        , uint8 _direction
        , address _from
        , address _to
    )
        public
        onlyRoadRealtyContract
    {
         
        assert(owners[_x][_y][_direction] == _from);

         
        owners[_x][_y][_direction] = _to;

         
        --roadCounts[_from];
        ++roadCounts[_to];
    }

     
     
     
     
     
     
    function buildRoads(
          uint _x
        , uint _y
        , uint8 _direction
        , uint _length
    )
        public
        payable
    {
         
        require(0 < _length);

         
        require(roadCost * _length == msg.value);

        KingOfEthBoard _boardContract = KingOfEthBoard(boardContract);

         
        require(_boardContract.boundX1() <= _x);
        require(_boardContract.boundY1() <= _y);
        require(_boardContract.boundX2() > _x);
        require(_boardContract.boundY2() > _y);

         
        KingOfEthResourcesInterface(interfaceContract).burnRoadCosts(
              _length
            , msg.sender
        );

         
        if(0 == _direction)
        {
             
            require(_boardContract.boundX2() > _x + _length);

            buildRight(_x, _y, _length);
        }
         
        else if(1 == _direction)
        {
             
            require(_boardContract.boundY2() > _y + _length);

            buildDown(_x, _y, _length);
        }
         
        else if(2 == _direction)
        {
             
            require(_boardContract.boundX1() < _x - _length - 1);

            buildLeft(_x, _y, _length);
        }
         
        else if(3 == _direction)
        {
             
            require(_boardContract.boundY1() < _y - _length - 1);

            buildUp(_x, _y, _length);
        }
        else
        {
             
            revert();
        }

         
        roadCounts[msg.sender] += _length;

         
        KingOfEthAbstractInterface(kingOfEthContract).payTaxes.value(msg.value)();

        emit NewRoads(msg.sender, _x, _y, _direction, _length);
    }

     
     
     
     
     
    function sendRoad(uint _x, uint _y, uint8 _direction, address _to)
        public
        onlyRoadOwner(_x, _y, _direction)
    {
         
        owners[_x][_y][_direction] = _to;

         
        --roadCounts[msg.sender];
        ++roadCounts[_to];

         
        KingOfEthRoadRealty(roadRealtyContract).roadsCancelRoadSale(
              _x
            , _y
            , _direction
        );

        emit SentRoad(_x, _y, _direction, msg.sender, _to);
    }
}

 

 

pragma solidity ^0.4.24;








 
 
 
contract KingOfEth is
      GodMode
    , KingOfEthHousesReferencer
    , KingOfEthRoadsReferencer
    , KingOfEthResourcesInterfaceReferencer
{
     
    uint public constant kingsTaxDivisor = 5;

     
    uint public constant wayfarersTaxDivisor = 20;

     
    uint public constant parliamentsTaxDivisor = 4;

     
     
    uint public constant timeBetweenClaims = 2 weeks;

     
     
    uint public constant gracePeriod = 1 days;

     
    address public king;

     
    uint public kingsTaxes;

     
    uint public kingsTaxesLastClaimed;

     
    address public wayfarer;

     
    uint public wayfarersTaxes;

     
    uint public wayfarersTaxesLastClaimed;

     
    struct ParliamentSeatData {
         
        uint points;

         
         
        uint unclaimedTaxes;
    }

     
    address[10] public parliamentSeats;

     
     
    mapping (address => ParliamentSeatData) parliamentSeatData;

     
    uint public parliamentsTaxes;

     
    uint public parliamentsTaxesLastDistributed;

     
     
    constructor(address _interfaceContract) public
    {
        interfaceContract = _interfaceContract;

         
        isPaused = true;
    }

     
    event KingsTaxesClaimed(address king, uint claimedTime);

     
    event WayfarersTaxesClaimed(address wayfarer, uint claimedTime);

     
     
    event ParliamentTaxesClaimed(address seat);

     
    event NewKing(address king);

     
    event NewWayfarer(address wayfarer);

     
    event ParliamentSeatClaimed(address seat, uint points);

     
     
    event ParliamentInquest(address seat, uint points);

     
    event ParliamentsTaxesDistributed(
          address distributor
        , uint share
        , uint distributedTime
    );

     
    event ParliamentOverthrown(uint overthrownTime);

     
    event KingOverthrown(uint overthrownTime);

     
    modifier onlyKing()
    {
        require(king == msg.sender);
        _;
    }

     
    modifier onlyWayfarer()
    {
        require(wayfarer == msg.sender);
        _;
    }

     
    modifier onlyParliamentSeat()
    {
        require(0 != parliamentSeatData[msg.sender].points);
        _;
    }

     
    function godWithdrawTaxes()
        public
        onlyGod
    {
         
        uint _parliamentsUnclaimed = 0;
        for(uint8 _i = 0; _i < 10; ++_i)
        {
            _parliamentsUnclaimed += parliamentSeatData[parliamentSeats[_i]].unclaimedTaxes;
        }

         
         
        uint taxes = address(this).balance - kingsTaxes - wayfarersTaxes
                   - parliamentsTaxes - _parliamentsUnclaimed;

        god.transfer(taxes);
    }

     
    function godStartGame() public onlyGod
    {
         
        kingsTaxesLastClaimed           = now;
        wayfarersTaxesLastClaimed       = now;
        parliamentsTaxesLastDistributed = now;

         
        isPaused = false;
    }

     
    function kingWithdrawTaxes()
        public
        onlyKing
    {
         
        require(kingsTaxesLastClaimed + timeBetweenClaims < now);

         
        kingsTaxesLastClaimed = now;

         
        uint _taxes = kingsTaxes;

         
        kingsTaxes = 0;

        king.transfer(_taxes);

        emit KingsTaxesClaimed(msg.sender, now);
    }

     
    function wayfarerWithdrawTaxes()
        public
        onlyWayfarer
    {
         
        require(wayfarersTaxesLastClaimed + timeBetweenClaims < now);

         
        wayfarersTaxesLastClaimed = now;

         
        uint _taxes = wayfarersTaxes;

         
        wayfarersTaxes = 0;

        wayfarer.transfer(_taxes);

        emit WayfarersTaxesClaimed(msg.sender, now);
    }

     
    function parliamentWithdrawTaxes()
        public
    {
         
        ParliamentSeatData storage _senderData = parliamentSeatData[msg.sender];

         
        if(0 != _senderData.unclaimedTaxes)
        {
             
            uint _taxes = _senderData.unclaimedTaxes;

             
            _senderData.unclaimedTaxes = 0;

             
            msg.sender.transfer(_taxes);
        }

        emit ParliamentTaxesClaimed(msg.sender);
    }

     
    function claimThrone() public
    {
        KingOfEthHouses _housesContract = KingOfEthHouses(housesContract);

         
        require(_housesContract.numberOfPoints(king) < _housesContract.numberOfPoints(msg.sender));

         
        king = msg.sender;

        emit NewKing(msg.sender);
    }

     
    function claimWayfarerTitle() public
    {
        KingOfEthRoads _roadsContract = KingOfEthRoads(roadsContract);

         
        require(_roadsContract.numberOfRoads(wayfarer) < _roadsContract.numberOfRoads(msg.sender));

         
        wayfarer = msg.sender;

        emit NewWayfarer(msg.sender);
    }

     
    function claimParliamentSeat() public
    {
         
        ParliamentSeatData storage _senderData = parliamentSeatData[msg.sender];

         
        if(0 == _senderData.points)
        {
             
            uint _points
                = KingOfEthResourcesInterface(interfaceContract).lookupResourcePoints(msg.sender);

             
            ParliamentSeatData storage _lastSeat = parliamentSeatData[parliamentSeats[9]];

             
            if(_lastSeat.points < _points)
            {
                 
                if(0 != _lastSeat.unclaimedTaxes)
                {
                     
                    parliamentsTaxes += _lastSeat.unclaimedTaxes;
                }

                 
                delete parliamentSeatData[parliamentSeats[9]];

                 
                _senderData.points = _points;

                 
                parliamentSeats[_i] = msg.sender;

                uint8 _i;

                 
                for(_i = 8; _i >= 0; --_i)
                {
                     
                    if(parliamentSeatData[parliamentSeats[_i]].points < _points)
                    {
                         
                        parliamentSeats[_i + 1] = parliamentSeats[_i];
                    }
                    else
                    {
                         
                        parliamentSeats[_i] = msg.sender;

                        break;
                    }
                }

                emit ParliamentSeatClaimed(msg.sender, _points);
            }
        }
    }

     
     
    function parliamentInquest(address _seat) public
    {
         
        ParliamentSeatData storage _seatData = parliamentSeatData[_seat];

         
        if(0 != _seatData.points)
        {
             
            uint _newPoints
                = KingOfEthResourcesInterface(interfaceContract).lookupResourcePoints(_seat);

            uint _i;

             
            if(_seatData.points < _newPoints)
            {
                 
                _i = 9;
                while(_seat != parliamentSeats[_i])
                {
                    --_i;
                }

                 
                for(; _i > 0; --_i)
                {
                     
                    if(parliamentSeatData[parliamentSeats[_i - 1]].points < _newPoints)
                    {
                         
                        parliamentSeats[_i] = parliamentSeats[_i - 1];
                    }
                    else
                    {
                         
                        parliamentSeats[_i] = _seat;

                        break;
                    }
                }
            }
             
            else if(_seatData.points == _newPoints)
            {
                revert();
            }
             
            else
            {
                 
                _i = 0;
                while(_seat != parliamentSeats[_i])
                {
                    ++_i;
                }

                 
                for(; _i < 10; ++_i)
                {
                     
                    if(parliamentSeatData[parliamentSeats[_i + 1]].points > _newPoints)
                    {
                         
                        parliamentSeats[_i] = parliamentSeats[_i + 1];
                    }
                    else
                    {
                         
                        parliamentSeats[_i] = _seat;

                        break;
                    }
                }
            }

             
            _seatData.points = _newPoints;

            emit ParliamentInquest(_seat, _newPoints);
        }
    }

     
     
    function distributeParliamentTaxes()
        public
        onlyParliamentSeat
    {
         
         
        require(parliamentsTaxesLastDistributed + timeBetweenClaims < now);

         
         
        uint _share = parliamentsTaxes / 11;

         
        uint _distributorsShare = parliamentsTaxes - _share * 9;

         
        parliamentsTaxes = 0;

         
        for(uint8 _i = 0; _i < 10; ++_i)
        {
             
            if(msg.sender != parliamentSeats[_i])
            {
                 
                parliamentSeatData[parliamentSeats[_i]].unclaimedTaxes += _share;
            }
        }

         
        parliamentsTaxesLastDistributed = now;

         
        msg.sender.transfer(_distributorsShare);

        emit ParliamentsTaxesDistributed(msg.sender, _share, now);
    }

     
     
    function overthrowParliament()
        public
        onlyKing
    {
         
         
        require(parliamentsTaxesLastDistributed + timeBetweenClaims + gracePeriod < now);

         
        kingsTaxes += parliamentsTaxes;

         
        parliamentsTaxes = 0;

         
        parliamentsTaxesLastDistributed = now;

        emit ParliamentOverthrown(now);
    }

     
     
    function overthrowKing()
        public
        onlyParliamentSeat
    {
         
         
        require(kingsTaxesLastClaimed + timeBetweenClaims + gracePeriod < now);

         
        parliamentsTaxes += kingsTaxes;

         
        kingsTaxes = 0;

         
        kingsTaxesLastClaimed = now;

        emit KingOverthrown(now);
    }

     
    function payTaxes() public payable
    {
         
        kingsTaxes += msg.value / kingsTaxDivisor;

         
        wayfarersTaxes += msg.value / wayfarersTaxDivisor;

         
        parliamentsTaxes += msg.value / parliamentsTaxDivisor;
    }
}