 

 

 

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