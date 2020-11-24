 

pragma solidity ^0.4.24;

contract Ownable {
    address public owner;

    function Ownable()
        public
    {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

library SafeMath {
    function safeMul(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b)
        internal
        pure
        returns (uint256)
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}


 

contract BytesToTypes {


    function bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToBool(uint _offst, bytes memory _input) internal pure returns (bool _output) {

        uint8 x;
        assembly {
            x := mload(add(_input, _offst))
        }
        x==0 ? _output = false : _output = true;
    }

    function getStringSize(uint _offst, bytes memory _input) internal pure returns(uint size){

        assembly{

            size := mload(add(_input,_offst))
            let chunk_count := add(div(size,32),1)  

            if gt(mod(size,32),0) { 
                chunk_count := add(chunk_count,1)
            }

             size := mul(chunk_count,32) 
        }
    }

    function bytesToString(uint _offst, bytes memory _input, bytes memory _output) internal  {

        uint size = 32;
        assembly {
            let loop_index:= 0

            let chunk_count

            size := mload(add(_input,_offst))
            chunk_count := add(div(size,32),1)  

            if gt(mod(size,32),0) {
                chunk_count := add(chunk_count,1)   
            }


            loop:
                mstore(add(_output,mul(loop_index,32)),mload(add(_input,_offst)))
                _offst := sub(_offst,32)            
                loop_index := add(loop_index,1)

            jumpi(loop , lt(loop_index , chunk_count))

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


    function bytesToBytes32(uint _offst, bytes memory  _input) internal pure returns (bytes32 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt8(uint _offst, bytes memory  _input) internal pure returns (int8 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt16(uint _offst, bytes memory _input) internal pure returns (int16 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt24(uint _offst, bytes memory _input) internal pure returns (int24 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt32(uint _offst, bytes memory _input) internal pure returns (int32 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt40(uint _offst, bytes memory _input) internal pure returns (int40 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt48(uint _offst, bytes memory _input) internal pure returns (int48 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt56(uint _offst, bytes memory _input) internal pure returns (int56 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt64(uint _offst, bytes memory _input) internal pure returns (int64 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt72(uint _offst, bytes memory _input) internal pure returns (int72 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt80(uint _offst, bytes memory _input) internal pure returns (int80 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt88(uint _offst, bytes memory _input) internal pure returns (int88 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt96(uint _offst, bytes memory _input) internal pure returns (int96 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToInt104(uint _offst, bytes memory _input) internal pure returns (int104 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt112(uint _offst, bytes memory _input) internal pure returns (int112 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt120(uint _offst, bytes memory _input) internal pure returns (int120 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt128(uint _offst, bytes memory _input) internal pure returns (int128 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt136(uint _offst, bytes memory _input) internal pure returns (int136 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt144(uint _offst, bytes memory _input) internal pure returns (int144 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt152(uint _offst, bytes memory _input) internal pure returns (int152 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt160(uint _offst, bytes memory _input) internal pure returns (int160 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt168(uint _offst, bytes memory _input) internal pure returns (int168 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt176(uint _offst, bytes memory _input) internal pure returns (int176 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt184(uint _offst, bytes memory _input) internal pure returns (int184 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt192(uint _offst, bytes memory _input) internal pure returns (int192 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt200(uint _offst, bytes memory _input) internal pure returns (int200 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt208(uint _offst, bytes memory _input) internal pure returns (int208 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt216(uint _offst, bytes memory _input) internal pure returns (int216 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt224(uint _offst, bytes memory _input) internal pure returns (int224 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt232(uint _offst, bytes memory _input) internal pure returns (int232 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt240(uint _offst, bytes memory _input) internal pure returns (int240 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt248(uint _offst, bytes memory _input) internal pure returns (int248 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToInt256(uint _offst, bytes memory _input) internal pure returns (int256 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint8(uint _offst, bytes memory _input) internal pure returns (uint8 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint16(uint _offst, bytes memory _input) internal pure returns (uint16 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint24(uint _offst, bytes memory _input) internal pure returns (uint24 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint32(uint _offst, bytes memory _input) internal pure returns (uint32 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint40(uint _offst, bytes memory _input) internal pure returns (uint40 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint48(uint _offst, bytes memory _input) internal pure returns (uint48 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint56(uint _offst, bytes memory _input) internal pure returns (uint56 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint64(uint _offst, bytes memory _input) internal pure returns (uint64 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint72(uint _offst, bytes memory _input) internal pure returns (uint72 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint80(uint _offst, bytes memory _input) internal pure returns (uint80 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint88(uint _offst, bytes memory _input) internal pure returns (uint88 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint96(uint _offst, bytes memory _input) internal pure returns (uint96 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

	function bytesToUint104(uint _offst, bytes memory _input) internal pure returns (uint104 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint112(uint _offst, bytes memory _input) internal pure returns (uint112 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint120(uint _offst, bytes memory _input) internal pure returns (uint120 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint128(uint _offst, bytes memory _input) internal pure returns (uint128 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint136(uint _offst, bytes memory _input) internal pure returns (uint136 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint144(uint _offst, bytes memory _input) internal pure returns (uint144 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint152(uint _offst, bytes memory _input) internal pure returns (uint152 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint160(uint _offst, bytes memory _input) internal pure returns (uint160 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint168(uint _offst, bytes memory _input) internal pure returns (uint168 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint176(uint _offst, bytes memory _input) internal pure returns (uint176 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint184(uint _offst, bytes memory _input) internal pure returns (uint184 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint192(uint _offst, bytes memory _input) internal pure returns (uint192 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint200(uint _offst, bytes memory _input) internal pure returns (uint200 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint208(uint _offst, bytes memory _input) internal pure returns (uint208 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint216(uint _offst, bytes memory _input) internal pure returns (uint216 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint224(uint _offst, bytes memory _input) internal pure returns (uint224 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint232(uint _offst, bytes memory _input) internal pure returns (uint232 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint240(uint _offst, bytes memory _input) internal pure returns (uint240 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint248(uint _offst, bytes memory _input) internal pure returns (uint248 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    function bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {

        assembly {
            _output := mload(add(_input, _offst))
        }
    }

}

interface ITradeable {

     
     
    function balanceOf(address _owner) external view returns (uint balance);

     
     
     
     
    function transfer(address _to, uint _value) external returns (bool success);

     
     
     
     
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);

     
     
     
     
    function approve(address _spender, uint _value) external returns (bool success);

     
     
     
    function allowance(address _owner, address _spender) external view returns (uint remaining);
}


contract ITrader {

  function getDataLength(
  ) public pure returns (uint256);

  function getProtocol(
  ) public pure returns (uint8);

  function getAvailableVolume(
    bytes orderData
  ) public view returns(uint);

  function isExpired(
    bytes orderData
  ) public view returns (bool);

  function trade(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public;

  function getFillVolumes(
    bool isSell,
    bytes orderData,
    uint volume,
    uint volumeEth
  ) public view returns(uint, uint);

}

contract ITraders {

   
  function addTrader(uint8 id, ITrader trader) public;

   
  function removeTrader(uint8 id) public;

   
  function getTrader(uint8 id) public view returns(ITrader);

   
  function isValidTraderAddress(address addr) public view returns(bool);

}

contract Members is Ownable {

  mapping(address => bool) public members;  

  modifier onlyMembers() {
    require(isValidMember(msg.sender));
    _;
  }

   
  function isValidMember(address _member) public view returns(bool) {
    return members[_member];
  }

   
  function addMember(address _member) public onlyOwner {
    members[_member] = true;
  }

   
  function removeMember(address _member) public onlyOwner {
    delete members[_member];
  }
}

contract ZodiacERC20 is Ownable, BytesToTypes {
  ITraders public traders;  
  bool public tradingEnabled;  
  uint feePercentage;
  event Sell(
    address account,
    address destinationAddr,
    address traedeable,
    uint volume,
    uint volumeEth,
    uint volumeEffective,
    uint volumeEthEffective
  );
  event Buy(
    address account,
    address destinationAddr,
    address traedeable,
    uint volume,
    uint volumeEth,
    uint volumeEffective,
    uint volumeEthEffective
  );


  function ZodiacERC20(ITraders _traders, uint _feePercentage) public {
    traders = _traders;
    tradingEnabled = true;
    feePercentage = _feePercentage;
  }

   
  function() public payable {
   
  }

  function changeFeePercentage(uint _feePercentage) public onlyOwner {
    feePercentage = _feePercentage;
  }

   
  function changeTraders(ITraders _traders) public onlyOwner {
    traders = _traders;
  }

   
  function changeTradingEnabled(bool enabled) public onlyOwner {
    tradingEnabled = enabled;
  }

   
  function buy(
    ITradeable tradeable,
    uint volume,
    bytes ordersData,
    address destinationAddr,
    address affiliate
  ) external payable
  {

    require(tradingEnabled);

     
    trade(
      false,
      tradeable,
      volume,
      ordersData,
      affiliate
    );

     
    uint volumeEffective = tradeable.balanceOf(this);

     
    require(volumeEffective > 0);

     
     
    uint volumeEthEffective = SafeMath.safeSub(msg.value, address(this).balance);

     
    require(
      SafeMath.safeDiv(volumeEthEffective, volumeEffective) <=
      SafeMath.safeDiv(msg.value, volume)
    );

     
    if(address(this).balance > 0) {
      destinationAddr.transfer(address(this).balance);
    }

     
    transferTradeable(tradeable, destinationAddr, volumeEffective);

    emit Buy(msg.sender, destinationAddr, tradeable, volume, msg.value, volumeEffective, volumeEthEffective);
  }

   
  function sell(
    ITradeable tradeable,
    uint volume,
    uint volumeEth,
    bytes ordersData,
    address destinationAddr,
    address affiliate
  ) external
  {
    require(tradingEnabled);

     
     
    require(tradeable.transferFrom(msg.sender, this, volume));

     
    trade(
      true,
      tradeable,
      volume,
      ordersData,
      affiliate
    );

     
     
    uint volumeEffective = SafeMath.safeSub(volume, tradeable.balanceOf(this));

     
    require(volumeEffective > 0);

     
    uint volumeEthEffective = collectSellFee();

     
    require(
      SafeMath.safeDiv(volumeEthEffective, volumeEffective) >=
      SafeMath.safeDiv(volumeEth, volume)
    );

     
    if (volumeEffective < volume) {
     transferTradeable(tradeable, destinationAddr, SafeMath.safeSub(volume, volumeEffective));
    }

     
    destinationAddr.transfer(volumeEthEffective);

    emit Sell(msg.sender, destinationAddr, tradeable, volume, volumeEth, volumeEffective, volumeEthEffective);
  }


   
  function trade(
    bool isSell,
    ITradeable tradeable,
    uint volume,
    bytes ordersData,
    address affiliate
  ) internal
  {
    uint remainingVolume = volume;
    uint offset = ordersData.length;

    while(offset > 0 && remainingVolume > 0) {
       
      uint8 protocolId = bytesToUint8(offset, ordersData);
      ITrader trader = traders.getTrader(protocolId);
      require(trader != address(0));

       
      uint dataLength = trader.getDataLength();
      offset = SafeMath.safeSub(offset, dataLength);
      bytes memory orderData = slice(ordersData, offset, dataLength);

       
      remainingVolume = fillOrder(
         isSell,
         tradeable,
         trader,
         remainingVolume,
         orderData,
         affiliate
      );
    }
  }

   
  function fillOrder(
    bool isSell,
    ITradeable tradeable,
    ITrader trader,
    uint remaining,
    bytes memory orderData,
    address affiliate
    ) internal returns(uint)
  {

     
    uint volume;
    uint volumeEth;
    (volume, volumeEth) = trader.getFillVolumes(
      isSell,
      orderData,
      remaining,
      address(this).balance
    );

    if(volume > 0) {

      if(isSell) {
         
        require(tradeable.approve(trader, volume));
      } else {
         
         
         
        volumeEth = collectFee(volumeEth);
        address(trader).transfer(volumeEth);
      }

       
      trader.trade(
        isSell,
        orderData,
        volume,
        volumeEth
      );

    }

    return SafeMath.safeSub(remaining, volume);
  }

   
  function transferTradeable(ITradeable tradeable, address account, uint amount) internal {
    require(tradeable.transfer(account, amount));
  }

   
  function collectFee(uint ethers) internal returns(uint) {
    uint fee = SafeMath.safeMul(ethers, feePercentage) / (1 ether);
    owner.transfer(fee);
    uint remaining = SafeMath.safeSub(ethers, fee);
    return remaining;
  }

   
  function collectSellFee() internal returns(uint) {
    uint fee = SafeMath.safeMul(address(this).balance, feePercentage) / (1 ether);
    owner.transfer(fee);
    return address(this).balance;
  }

}