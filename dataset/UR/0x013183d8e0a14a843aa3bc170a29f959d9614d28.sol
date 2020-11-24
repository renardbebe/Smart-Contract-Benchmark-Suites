 

contract Certifier {
	event Confirmed(address indexed who);
	event Revoked(address indexed who);
	function certified(address _who) view public returns (bool);
}

contract ERC223ReceivingContract {

     
     
     
     
    function tokenFallback(address _from, uint _value, bytes _data) public;

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC223Basic is ERC20Basic {

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
}


contract SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract DetherBank is ERC223ReceivingContract, Ownable, SafeMath  {
  using BytesLib for bytes;

   
  event receiveDth(address _from, uint amount);
  event receiveEth(address _from, uint amount);
  event sendDth(address _from, uint amount);
  event sendEth(address _from, uint amount);

  mapping(address => uint) public dthShopBalance;
  mapping(address => uint) public dthTellerBalance;
  mapping(address => uint) public ethShopBalance;
  mapping(address => uint) public ethTellerBalance;

  ERC223Basic public dth;
  bool public isInit = false;

   
  function setDth (address _dth) external onlyOwner {
    require(!isInit);
    dth = ERC223Basic(_dth);
    isInit = true;
  }

   
   
  function withdrawDthTeller(address _receiver) external onlyOwner {
    require(dthTellerBalance[_receiver] > 0);
    uint tosend = dthTellerBalance[_receiver];
    dthTellerBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
   
  function withdrawDthShop(address _receiver) external onlyOwner  {
    require(dthShopBalance[_receiver] > 0);
    uint tosend = dthShopBalance[_receiver];
    dthShopBalance[_receiver] = 0;
    require(dth.transfer(_receiver, tosend));
  }
   
  function withdrawDthShopAdmin(address _from, address _receiver) external onlyOwner  {
    require(dthShopBalance[_from]  > 0);
    uint tosend = dthShopBalance[_from];
    dthShopBalance[_from] = 0;
    require(dth.transfer(_receiver, tosend));
  }

   
  function addTokenShop(address _from, uint _value) external onlyOwner {
    dthShopBalance[_from] = SafeMath.add(dthShopBalance[_from], _value);
  }
   
  function addTokenTeller(address _from, uint _value) external onlyOwner{
    dthTellerBalance[_from] = SafeMath.add(dthTellerBalance[_from], _value);
  }
   
  function addEthTeller(address _from, uint _value) external payable onlyOwner returns (bool) {
    ethTellerBalance[_from] = SafeMath.add(ethTellerBalance[_from] ,_value);
    return true;
  }
   
  function withdrawEth(address _from, address _to, uint _amount) external onlyOwner {
    require(ethTellerBalance[_from] >= _amount);
    ethTellerBalance[_from] = SafeMath.sub(ethTellerBalance[_from], _amount);
    _to.transfer(_amount);
  }
   
  function refundEth(address _from) external onlyOwner {
    uint toSend = ethTellerBalance[_from];
    if (toSend > 0) {
      ethTellerBalance[_from] = 0;
      _from.transfer(toSend);
    }
  }

   
  function getDthTeller(address _user) public view returns (uint) {
    return dthTellerBalance[_user];
  }
  function getDthShop(address _user) public view returns (uint) {
    return dthShopBalance[_user];
  }

  function getEthBalTeller(address _user) public view returns (uint) {
    return ethTellerBalance[_user];
  }
   
   
   
  function tokenFallback(address _from, uint _value, bytes _data) {
    require(msg.sender == address(dth));
  }

}


contract DetherAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cmoAddress;
    address public csoAddress;  
	  mapping (address => bool) public shopModerators;    
    mapping (address => bool) public tellerModerators;    

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCMO() {
        require(msg.sender == cmoAddress);
        _;
    }

    function isCSO(address _addr) public view returns (bool) {
      return (_addr == csoAddress);
    }


    modifier isShopModerator(address _user) {
      require(shopModerators[_user]);
      _;
    }
    modifier isTellerModerator(address _user) {
      require(tellerModerators[_user]);
      _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

     
     
    function setCMO(address _newCMO) external onlyCEO {
        require(_newCMO != address(0));
        cmoAddress = _newCMO;
    }

    function setCSO(address _newCSO) external onlyCEO {
        require(_newCSO != address(0));
        csoAddress = _newCSO;
    }

    function setShopModerator(address _moderator) external onlyCEO {
      require(_moderator != address(0));
      shopModerators[_moderator] = true;
    }

    function removeShopModerator(address _moderator) external onlyCEO {
      shopModerators[_moderator] = false;
    }

    function setTellerModerator(address _moderator) external onlyCEO {
      require(_moderator != address(0));
      tellerModerators[_moderator] = true;
    }

    function removeTellerModerator(address _moderator) external onlyCEO {
      tellerModerators[_moderator] = false;
    }
     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

contract DetherSetup is DetherAccessControl  {

  bool public run1 = false;
  bool public run2 = false;
   
   
   
   
  Certifier public smsCertifier;
  Certifier public kycCertifier;
   
   
  mapping(bytes2 => bool) public openedCountryShop;
  mapping(bytes2 => bool) public openedCountryTeller;
   
   
   
   
  mapping(bytes2 => uint) public licenceShop;
  mapping(bytes2 => uint) public licenceTeller;

  modifier tier1(address _user) {
    require(smsCertifier.certified(_user));
    _;
  }
  modifier tier2(address _user) {
    require(kycCertifier.certified(_user));
    _;
  }
  modifier isZoneShopOpen(bytes2 _country) {
    require(openedCountryShop[_country]);
    _;
  }
  modifier isZoneTellerOpen(bytes2 _country) {
    require(openedCountryTeller[_country]);
    _;
  }

   
  function setSmsCertifier (address _smsCertifier) external onlyCEO {
    require(!run1);
    smsCertifier = Certifier(_smsCertifier);
    run1 = true;
  }
   
  function setKycCertifier (address _kycCertifier) external onlyCEO {
    require(!run2);
    kycCertifier = Certifier(_kycCertifier);
    run2 = true;
  }
  function setLicenceShopPrice(bytes2 country, uint price) external onlyCMO {
    licenceShop[country] = price;
  }
  function setLicenceTellerPrice(bytes2 country, uint price) external onlyCMO {
    licenceTeller[country] = price;
  }
  function openZoneShop(bytes2 _country) external onlyCMO {
    openedCountryShop[_country] = true;
  }
  function closeZoneShop(bytes2 _country) external onlyCMO {
    openedCountryShop[_country] = false;
  }
  function openZoneTeller(bytes2 _country) external onlyCMO {
    openedCountryTeller[_country] = true;
  }
  function closeZoneTeller(bytes2 _country) external onlyCMO {
    openedCountryTeller[_country] = false;
  }
}



library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes) {
        bytes memory tempBytes;

        assembly {
             
             
            tempBytes := mload(0x40)

             
             
            let length := mload(_preBytes)
            mstore(tempBytes, length)

             
             
             
            let mc := add(tempBytes, 0x20)
             
             
            let end := add(mc, length)

            for {
                 
                 
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                 
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                 
                 
                mstore(mc, mload(cc))
            }

             
             
             
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

             
             
            mc := end
             
             
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

             
             
             
             
             
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31)  
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
             
             
             
            let fslot := sload(_preBytes_slot)
             
             
             
             
             
             
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
             
             
             
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                 
                 
                 
                sstore(
                    _preBytes_slot,
                     
                     
                    add(
                         
                         
                        fslot,
                        add(
                            mul(
                                div(
                                     
                                    mload(add(_postBytes, 0x20)),
                                     
                                    exp(0x100, sub(32, mlength))
                                ),
                                 
                                 
                                exp(0x100, sub(32, newlength))
                            ),
                             
                             
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                 
                 
                 
                mstore(0x0, _preBytes_slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                 
                 
                 
                 
                 
                 

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                 
                mstore(0x0, _preBytes_slot)
                 
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                 
                sstore(_preBytes_slot, add(mul(newlength, 2), 1))

                 
                 
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(bytes _bytes, uint _start, uint _length) internal  pure returns (bytes) {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                 
                 
                tempBytes := mload(0x40)

                 
                 
                 
                 
                 
                 
                 
                 
                let lengthmod := and(_length, 31)

                 
                 
                 
                 
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                     
                     
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                 
                 
                mstore(0x40, and(add(mc, 31), not(31)))
            }
             
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes _bytes, uint _start) internal  pure returns (address) {
        require(_bytes.length >= (_start + 20));
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes _bytes, uint _start) internal  pure returns (uint256) {
        require(_bytes.length >= (_start + 32));
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes _bytes, uint _start) internal  pure returns (bytes32) {
        require(_bytes.length >= (_start + 32));
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function toBytes16(bytes _bytes, uint _start) internal  pure returns (bytes16) {
        require(_bytes.length >= (_start + 16));
        bytes16 tempBytes16;

        assembly {
            tempBytes16 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes16;
    }

    function toBytes2(bytes _bytes, uint _start) internal  pure returns (bytes2) {
        require(_bytes.length >= (_start + 2));
        bytes2 tempBytes2;

        assembly {
            tempBytes2 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes2;
    }

    function toBytes4(bytes _bytes, uint _start) internal  pure returns (bytes4) {
        require(_bytes.length >= (_start + 4));
        bytes4 tempBytes4;

        assembly {
            tempBytes4 := mload(add(add(_bytes, 0x20), _start))
        }
        return tempBytes4;
    }

    function toBytes1(bytes _bytes, uint _start) internal  pure returns (bytes1) {
        require(_bytes.length >= (_start + 1));
        bytes1 tempBytes1;

        assembly {
            tempBytes1 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes1;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

             
            switch eq(length, mload(_postBytes))
            case 1 {
                 
                 
                 
                 
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                 
                 
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                     
                    if iszero(eq(mload(mc), mload(cc))) {
                         
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
             
            let fslot := sload(_preBytes_slot)
             
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

             
            switch eq(slength, mlength)
            case 1 {
                 
                 
                 
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                         
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                             
                            success := 0
                        }
                    }
                    default {
                         
                         
                         
                         
                        let cb := 1

                         
                        mstore(0x0, _preBytes_slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                         
                         
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                 
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                 
                success := 0
            }
        }

        return success;
    }
}


contract DetherCore is DetherSetup, ERC223ReceivingContract, SafeMath {
  using BytesLib for bytes;

   
   
  event RegisterTeller(address indexed tellerAddress);
   
  event DeleteTeller(address indexed tellerAddress);
   
  event UpdateTeller(address indexed tellerAddress);
   
  event Sent(address indexed _from, address indexed _to, uint amount);
   
  event RegisterShop(address shopAddress);
   
  event DeleteShop(address shopAddress);
   
  event DeleteShopModerator(address indexed moderator, address shopAddress);
   
  event DeleteTellerModerator(address indexed moderator, address tellerAddress);

   
   
  modifier tellerHasStaked(uint amount) {
    require(bank.getDthTeller(msg.sender) >= amount);
    _;
  }
   
  modifier shopHasStaked(uint amount) {
    require(bank.getDthShop(msg.sender) >= amount);
    _;
  }

   
   
  ERC223Basic public dth;
   
  DetherBank public bank;

   
  struct Teller {
    int32 lat;             
    int32 lng;             
    bytes2 countryId;      
    bytes16 postalCode;    

    int8 currencyId;       
    bytes16 messenger;     
    int8 avatarId;         
    int16 rates;           

    uint zoneIndex;        
    uint generalIndex;     
    bool online;           
  }

   
  mapping(address => uint) volumeBuy;
  mapping(address => uint) volumeSell;
  mapping(address => uint) nbTrade;

   
  mapping(address => Teller) teller;
   
  mapping(bytes2 => mapping(bytes16 => address[])) tellerInZone;
   
  address[] public tellerIndex;  
  bool isStarted = false;
   
  struct Shop {
    int32 lat;             
    int32 lng;             
    bytes2 countryId;      
    bytes16 postalCode;    
    bytes16 cat;           
    bytes16 name;          
    bytes32 description;   
    bytes16 opening;       

    uint zoneIndex;        
    uint generalIndex;     
    bool detherShop;       
  }

   
  mapping(address => Shop) shop;
   
  mapping(bytes2 => mapping(bytes16 => address[])) shopInZone;
   
  address[] public shopIndex;  

   
  function DetherCore() {
   ceoAddress = msg.sender;
  }
  function initContract (address _dth, address _bank) external onlyCEO {
    require(!isStarted);
    dth = ERC223Basic(_dth);
    bank = DetherBank(_bank);
    isStarted = true;
  }

   

   
  function tokenFallback(address _from, uint _value, bytes _data) whenNotPaused tier1(_from ) {
     
    require(msg.sender == address(dth));
     
     
    bytes1 _func = _data.toBytes1(0);
    int32 posLat = _data.toBytes1(1) == bytes1(0x01) ? int32(_data.toBytes4(2)) * -1 : int32(_data.toBytes4(2));
    int32 posLng = _data.toBytes1(6) == bytes1(0x01) ? int32(_data.toBytes4(7)) * -1 : int32(_data.toBytes4(7));
    if (_func == bytes1(0x31)) {  
       
      require(_value >= licenceShop[_data.toBytes2(11)]);
       
      require(!isShop(_from));
       
      require(openedCountryShop[_data.toBytes2(11)]);

      shop[_from].lat = posLat;
      shop[_from].lng = posLng;
      shop[_from].countryId = _data.toBytes2(11);
      shop[_from].postalCode = _data.toBytes16(13);
      shop[_from].cat = _data.toBytes16(29);
      shop[_from].name = _data.toBytes16(45);
      shop[_from].description = _data.toBytes32(61);
      shop[_from].opening = _data.toBytes16(93);
      shop[_from].generalIndex = shopIndex.push(_from) - 1;
      shop[_from].zoneIndex = shopInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(_from) - 1;
      emit RegisterShop(_from);
      bank.addTokenShop(_from,_value);
      dth.transfer(address(bank), _value);
    } else if (_func == bytes1(0x32)) {  
       
      require(_value >= licenceTeller[_data.toBytes2(11)]);
       
      require(!isTeller(_from));
       
      require(openedCountryTeller[_data.toBytes2(11)]);

      teller[_from].lat = posLat;
      teller[_from].lng = posLng;
      teller[_from].countryId = _data.toBytes2(11);
      teller[_from].postalCode = _data.toBytes16(13);
      teller[_from].avatarId = int8(_data.toBytes1(29));
      teller[_from].currencyId = int8(_data.toBytes1(30));
      teller[_from].messenger = _data.toBytes16(31);
      teller[_from].rates = int16(_data.toBytes2(47));
      teller[_from].generalIndex = tellerIndex.push(_from) - 1;
      teller[_from].zoneIndex = tellerInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(_from) - 1;
      teller[_from].online = true;
      emit RegisterTeller(_from);
      bank.addTokenTeller(_from, _value);
      dth.transfer(address(bank), _value);
    } else if (_func == bytes1(0x33)) {   
       
       
       
       
       

       
      require(_from == csoAddress);
       
      require(_value >= licenceShop[_data.toBytes2(11)]);
       
      require(!isShop(address(_data.toAddress(109))));
       
      require(openedCountryShop[_data.toBytes2(11)]);
      address newShopAddress = _data.toAddress(109);
      shop[newShopAddress].lat = posLat;
      shop[newShopAddress].lng = posLng;
      shop[newShopAddress].countryId = _data.toBytes2(11);
      shop[newShopAddress].postalCode = _data.toBytes16(13);
      shop[newShopAddress].cat = _data.toBytes16(29);
      shop[newShopAddress].name = _data.toBytes16(45);
      shop[newShopAddress].description = _data.toBytes32(61);
      shop[newShopAddress].opening = _data.toBytes16(93);
      shop[newShopAddress].generalIndex = shopIndex.push(newShopAddress) - 1;
      shop[newShopAddress].zoneIndex = shopInZone[_data.toBytes2(11)][_data.toBytes16(13)].push(newShopAddress) - 1;
      shop[newShopAddress].detherShop = true;
      emit RegisterShop(newShopAddress);
      bank.addTokenShop(newShopAddress, _value);
      dth.transfer(address(bank), _value);
    }
  }

   
  function updateTeller(
    int8 currencyId,
    bytes16 messenger,
    int8 avatarId,
    int16 rates,
    bool online
   ) public payable {
    require(isTeller(msg.sender));
    if (currencyId != teller[msg.sender].currencyId)
    teller[msg.sender].currencyId = currencyId;
    if (teller[msg.sender].messenger != messenger)
     teller[msg.sender].messenger = messenger;
    if (teller[msg.sender].avatarId != avatarId)
     teller[msg.sender].avatarId = avatarId;
    if (teller[msg.sender].rates != rates)
     teller[msg.sender].rates = rates;
    if (teller[msg.sender].online != online)
      teller[msg.sender].online = online;
    if (msg.value > 0) {
      bank.addEthTeller.value(msg.value)(msg.sender, msg.value);
    }
    emit UpdateTeller(msg.sender);
  }

   
  function sellEth(address _to, uint _amount) whenNotPaused external {
    require(isTeller(msg.sender));
    require(_to != msg.sender);
     
    bank.withdrawEth(msg.sender, _to, _amount);
     
     
    if (smsCertifier.certified(_to)) {
      volumeBuy[_to] = SafeMath.add(volumeBuy[_to], _amount);
      volumeSell[msg.sender] = SafeMath.add(volumeSell[msg.sender], _amount);
      nbTrade[msg.sender] += 1;
    }
    emit Sent(msg.sender, _to, _amount);
  }

   
  function switchStatus(bool _status) external {
    if (teller[msg.sender].online != _status)
     teller[msg.sender].online = _status;
  }

   
  function addFunds() external payable {
    require(isTeller(msg.sender));
    require(bank.addEthTeller.value(msg.value)(msg.sender, msg.value));
  }

   
   
  function deleteTeller() external {
    require(isTeller(msg.sender));
    uint rowToDelete1 = teller[msg.sender].zoneIndex;
    address keyToMove1 = tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode][tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode].length - 1];
    tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode][rowToDelete1] = keyToMove1;
    teller[keyToMove1].zoneIndex = rowToDelete1;
    tellerInZone[teller[msg.sender].countryId][teller[msg.sender].postalCode].length--;

    uint rowToDelete2 = teller[msg.sender].generalIndex;
    address keyToMove2 = tellerIndex[tellerIndex.length - 1];
    tellerIndex[rowToDelete2] = keyToMove2;
    teller[keyToMove2].generalIndex = rowToDelete2;
    tellerIndex.length--;
    delete teller[msg.sender];
    bank.withdrawDthTeller(msg.sender);
    bank.refundEth(msg.sender);
    emit DeleteTeller(msg.sender);
  }

   
   
  function deleteTellerMods(address _toDelete) isTellerModerator(msg.sender) external {
    uint rowToDelete1 = teller[_toDelete].zoneIndex;
    address keyToMove1 = tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode][tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode].length - 1];
    tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode][rowToDelete1] = keyToMove1;
    teller[keyToMove1].zoneIndex = rowToDelete1;
    tellerInZone[teller[_toDelete].countryId][teller[_toDelete].postalCode].length--;

    uint rowToDelete2 = teller[_toDelete].generalIndex;
    address keyToMove2 = tellerIndex[tellerIndex.length - 1];
    tellerIndex[rowToDelete2] = keyToMove2;
    teller[keyToMove2].generalIndex = rowToDelete2;
    tellerIndex.length--;
    delete teller[_toDelete];
    bank.withdrawDthTeller(_toDelete);
    bank.refundEth(_toDelete);
    emit DeleteTellerModerator(msg.sender, _toDelete);
  }

   
   
  function deleteShop() external {
    require(isShop(msg.sender));
    uint rowToDelete1 = shop[msg.sender].zoneIndex;
    address keyToMove1 = shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode][shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode].length - 1];
    shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode][rowToDelete1] = keyToMove1;
    shop[keyToMove1].zoneIndex = rowToDelete1;
    shopInZone[shop[msg.sender].countryId][shop[msg.sender].postalCode].length--;

    uint rowToDelete2 = shop[msg.sender].generalIndex;
    address keyToMove2 = shopIndex[shopIndex.length - 1];
    shopIndex[rowToDelete2] = keyToMove2;
    shop[keyToMove2].generalIndex = rowToDelete2;
    shopIndex.length--;
    delete shop[msg.sender];
    bank.withdrawDthShop(msg.sender);
    emit DeleteShop(msg.sender);
  }

   
   
  function deleteShopMods(address _toDelete) isShopModerator(msg.sender) external {
    uint rowToDelete1 = shop[_toDelete].zoneIndex;
    address keyToMove1 = shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode][shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode].length - 1];
    shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode][rowToDelete1] = keyToMove1;
    shop[keyToMove1].zoneIndex = rowToDelete1;
    shopInZone[shop[_toDelete].countryId][shop[_toDelete].postalCode].length--;

    uint rowToDelete2 = shop[_toDelete].generalIndex;
    address keyToMove2 = shopIndex[shopIndex.length - 1];
    shopIndex[rowToDelete2] = keyToMove2;
    shop[keyToMove2].generalIndex = rowToDelete2;
    shopIndex.length--;
    if (!shop[_toDelete].detherShop)
      bank.withdrawDthShop(_toDelete);
    else
      bank.withdrawDthShopAdmin(_toDelete, csoAddress);
    delete shop[_toDelete];
    emit DeleteShopModerator(msg.sender, _toDelete);
  }

   

   
   
  function getTeller(address _teller) public view returns (
    int32 lat,
    int32 lng,
    bytes2 countryId,
    bytes16 postalCode,
    int8 currencyId,
    bytes16 messenger,
    int8 avatarId,
    int16 rates,
    uint balance,
    bool online,
    uint sellVolume,
    uint numTrade
    ) {
    Teller storage theTeller = teller[_teller];
    lat = theTeller.lat;
    lng = theTeller.lng;
    countryId = theTeller.countryId;
    postalCode = theTeller.postalCode;
    currencyId = theTeller.currencyId;
    messenger = theTeller.messenger;
    avatarId = theTeller.avatarId;
    rates = theTeller.rates;
    online = theTeller.online;
    sellVolume = volumeSell[_teller];
    numTrade = nbTrade[_teller];
    balance = bank.getEthBalTeller(_teller);
  }

   
  function getShop(address _shop) public view returns (
   int32 lat,
   int32 lng,
   bytes2 countryId,
   bytes16 postalCode,
   bytes16 cat,
   bytes16 name,
   bytes32 description,
   bytes16 opening
   ) {
    Shop storage theShop = shop[_shop];
    lat = theShop.lat;
    lng = theShop.lng;
    countryId = theShop.countryId;
    postalCode = theShop.postalCode;
    cat = theShop.cat;
    name = theShop.name;
    description = theShop.description;
    opening = theShop.opening;
   }

    
    
  function getReput(address _teller) public view returns (
   uint buyVolume,
   uint sellVolume,
   uint numTrade
   ) {
     buyVolume = volumeBuy[_teller];
     sellVolume = volumeSell[_teller];
     numTrade = nbTrade[_teller];
  }
   
  function getTellerBalance(address _teller) public view returns (uint) {
    return bank.getEthBalTeller(_teller);
  }

   
   
  function getZoneShop(bytes2 _country, bytes16 _postalcode) public view returns (address[]) {
     return shopInZone[_country][_postalcode];
  }

   
  function getAllShops() public view returns (address[]) {
   return shopIndex;
  }

  function isShop(address _shop) public view returns (bool ){
   return (shop[_shop].countryId != bytes2(0x0));
  }

   
   
  function getZoneTeller(bytes2 _country, bytes16 _postalcode) public view returns (address[]) {
     return tellerInZone[_country][_postalcode];
  }

   
  function getAllTellers() public view returns (address[]) {
   return tellerIndex;
  }

   
  function isTeller(address _teller) public view returns (bool ){
    return (teller[_teller].countryId != bytes2(0x0));
  }

   
    
  function getStakedShop(address _shop) public view returns (uint) {
    return bank.getDthShop(_shop);
  }
   
  function getStakedTeller(address _teller) public view returns (uint) {
    return bank.getDthTeller(_teller);
  }
   
  function transferBankOwnership(address _newbankowner) external onlyCEO whenPaused {
    bank.transferOwnership(_newbankowner);
  }
}