 

pragma solidity ^0.4.13;

contract ContractReceiver {
    function tokenFallback(address _from, uint _value, bytes _data) public;
}

contract PrivateSale is ContractReceiver {
    using SafeMath for uint256;

    Token tokContract;
    TimedEscrow escrow;
    address owner;
     
     
     
     
    uint256 rate;

     
    uint256 end;

    uint256 lockend1;

    uint256 lockend2;

    uint256 mincontrib;

    uint256 numerator;

    uint256 denominator;

    event Contribution(address from, uint256 eth, uint256 tokens);

    constructor(address _tokContract, address _escrowContract, uint256 _end, uint256 _lockend1, uint256 _lockend2, uint256 _numerator, uint256 _denominator, uint256 _mincontrib, uint256 _rate) public {
        tokContract = Token(_tokContract);
        escrow = TimedEscrow(_escrowContract);
        owner = msg.sender;
        end = _end;
        require(_rate > 0);
        rate = _rate;
        numerator = _numerator;
        require(_denominator > 0);
        denominator = _denominator;
        lockend1 = _lockend1;
        lockend2 = _lockend2;
        mincontrib = _mincontrib;
    }

    function getMinContrib() public view returns (uint256){
        return mincontrib;
    }

    function setMinContrib(uint256 _mincontrib){
        require(msg.sender == owner);
        mincontrib = _mincontrib;
    }

    function setLockend1(uint256 _lockend1){
        require(msg.sender == owner);
        require(_lockend1 <= lockend1);
        lockend1 = _lockend1;
    }

    function setLockend2(uint256 _lockend2){
        require(msg.sender == owner);
        require(_lockend2 <= lockend2);
        lockend2 = _lockend2;
    }

    function setLockRatio(uint256 _numerator, uint256 _denominator){
        require(msg.sender == owner);
        require(_denominator > 0);
        numerator = _numerator;
        denominator = _denominator;
    }

     
    function remaining() public view returns (uint) {
        return tokContract.balanceOf(this);
    }

     
    function withdrawTokens() public {
        require(now > end);
        require(msg.sender == owner);
        tokContract.transfer(owner, tokContract.balanceOf(this));
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
         
        require(_from == owner, "Only owner can send tokens");
    }

     
    function() public payable {
        require(now < end && msg.value >= mincontrib);
         
        owner.transfer(msg.value);

        uint256 toks = msg.value.mul(rate);

        emit Contribution(msg.sender, msg.value, toks);

        uint256 toks1 = toks.div(denominator).mul(numerator);

        uint256 toks2 = toks - toks1;

        bytes memory data = escrow.transactionRawToBytes(toks1, msg.sender, lockend1, true, false);

        bytes memory data2 = escrow.transactionRawToBytes(toks2, msg.sender, lockend2, true, false);

         
        tokContract.transfer(
            escrow,
            toks1,
            data
        );

        tokContract.transfer(
            escrow,
            toks2,
            data2
        );
    }

}

contract ERC20Interface {
     
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

     
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract StandardERC20 is ERC20Interface {
    using SafeMath for uint256;

    mapping(address => uint256) balances;
    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     

    mapping (address => mapping (address => uint256)) internal allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }


}

contract Token is StandardERC20 {
    
    string public name    = "Genuine Token";
    string public symbol  = "GNU";
    uint8  public decimals = 18;

    address owner;

    bool burnable;

    event Transfer(address indexed from, address indexed to, uint value, bytes data);

    event Burn(address indexed burner, uint256 value);


    constructor() public {
        balances[msg.sender] = 340000000 * (uint(10) ** decimals);
        totalSupply_ = balances[msg.sender];
        owner = msg.sender;
        burnable = false;
    }

    function transferOwnership(address tbo) public {
        require(msg.sender == owner, 'Unauthorized');
        owner = tbo;
    }
       
     
    function name() public view returns (string _name) {
        return name;
    }
    
     
    function symbol() public view returns (string _symbol) {
        return symbol;
    }
    
     
    function decimals() public view returns (uint8 _decimals) {
        return decimals;
    }
    
     
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply_;
    }
    
     
    function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {
        require(_to != address(0));

        if (isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(sha3(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
             
            emit Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }
  

     
    function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
        require(_to != address(0));
        
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
    
     
     
     
    function transfer(address _to, uint _value) public returns (bool success) {
        require(_to != address(0));
        
         
         
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
                 
                length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert("Insufficient balance");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
         
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert("Insufficient balance");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
         
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function setBurnable(bool _burnable) public {
        require (msg.sender == owner);
        burnable = _burnable;
    }

     
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {

        require(burnable == true || _who == owner);

        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}

library Array256Lib {

   
   
   
  function sumElements(uint256[] storage self) public view returns(uint256 sum) {
    assembly {
      mstore(0x60,self_slot)

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        sum := add(sload(add(sha3(0x60,0x20),i)),sum)
      }
    }
  }

   
   
   
  function getMax(uint256[] storage self) public view returns(uint256 maxValue) {
    assembly {
      mstore(0x60,self_slot)
      maxValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), maxValue)
        case 1 {
          maxValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

   
   
   
  function getMin(uint256[] storage self) public view returns(uint256 minValue) {
    assembly {
      mstore(0x60,self_slot)
      minValue := sload(sha3(0x60,0x20))

      for { let i := 0 } lt(i, sload(self_slot)) { i := add(i, 1) } {
        switch gt(sload(add(sha3(0x60,0x20),i)), minValue)
        case 0 {
          minValue := sload(add(sha3(0x60,0x20),i))
        }
      }
    }
  }

   
   
   
   
   
   
  function indexOf(uint256[] storage self, uint256 value, bool isSorted)
           public
           view
           returns(bool found, uint256 index) {
    assembly{
      mstore(0x60,self_slot)
      switch isSorted
      case 1 {
        let high := sub(sload(self_slot),1)
        let mid := 0
        let low := 0
        for { } iszero(gt(low, high)) { } {
          mid := div(add(low,high),2)

          switch lt(sload(add(sha3(0x60,0x20),mid)),value)
          case 1 {
             low := add(mid,1)
          }
          case 0 {
            switch gt(sload(add(sha3(0x60,0x20),mid)),value)
            case 1 {
              high := sub(mid,1)
            }
            case 0 {
              found := 1
              index := mid
              low := add(high,1)
            }
          }
        }
      }
      case 0 {
        for { let low := 0 } lt(low, sload(self_slot)) { low := add(low, 1) } {
          switch eq(sload(add(sha3(0x60,0x20),low)), value)
          case 1 {
            found := 1
            index := low
            low := sload(self_slot)
          }
        }
      }
    }
  }

   
   
   
  function getParentI(uint256 index) private pure returns (uint256 pI) {
    uint256 i = index - 1;
    pI = i/2;
  }

   
   
   
  function getLeftChildI(uint256 index) private pure returns (uint256 lcI) {
    uint256 i = index * 2;
    lcI = i + 1;
  }

   
   
  function heapSort(uint256[] storage self) public {
    uint256 end = self.length - 1;
    uint256 start = getParentI(end);
    uint256 root = start;
    uint256 lChild;
    uint256 rChild;
    uint256 swap;
    uint256 temp;
    while(start >= 0){
      root = start;
      lChild = getLeftChildI(start);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end+1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
      if(start == 0)
        break;
      else
        start = start - 1;
    }
    while(end > 0){
      temp = self[end];
      self[end] = self[0];
      self[0] = temp;
      end = end - 1;
      root = 0;
      lChild = getLeftChildI(0);
      while(lChild <= end){
        rChild = lChild + 1;
        swap = root;
        if(self[swap] < self[lChild])
          swap = lChild;
        if((rChild <= end) && (self[swap]<self[rChild]))
          swap = rChild;
        if(swap == root)
          lChild = end + 1;
        else {
          temp = self[swap];
          self[swap] = self[root];
          self[root] = temp;
          root = swap;
          lChild = getLeftChildI(root);
        }
      }
    }
  }

   
   
  function uniq(uint256[] storage self) public returns (uint256 length) {
    bool contains;
    uint256 index;

    for (uint256 i = 0; i < self.length; i++) {
      (contains, index) = indexOf(self, self[i], false);

      if (i > index) {
        for (uint256 j = i; j < self.length - 1; j++){
          self[j] = self[j + 1];
        }

        delete self[self.length - 1];
        self.length--;
        i--;
      }
    }

    length = self.length;
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

    function bytesToBytes32(uint _offst, bytes memory  _input, bytes32 _output) internal pure {
        
        assembly {
            mstore(_output , add(_input, _offst))
            mstore(add(_output,32) , add(add(_input, _offst),32))
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

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract  SizeOf {
    
    function sizeOfString(string _in) internal pure  returns(uint _size){
        _size = bytes(_in).length / 32;
         if(bytes(_in).length % 32 != 0) 
            _size++;
            
        _size++;  
        _size *= 32;
    }

    function sizeOfInt(uint16 _postfix) internal pure  returns(uint size){

        assembly{
            switch _postfix
                case 8 { size := 1 }
                case 16 { size := 2 }
                case 24 { size := 3 }
                case 32 { size := 4 }
                case 40 { size := 5 }
                case 48 { size := 6 }
                case 56 { size := 7 }
                case 64 { size := 8 }
                case 72 { size := 9 }
                case 80 { size := 10 }
                case 88 { size := 11 }
                case 96 { size := 12 }
                case 104 { size := 13 }
                case 112 { size := 14 }
                case 120 { size := 15 }
                case 128 { size := 16 }
                case 136 { size := 17 }
                case 144 { size := 18 }
                case 152 { size := 19 }
                case 160 { size := 20 }
                case 168 { size := 21 }
                case 176 { size := 22 }
                case 184 { size := 23 }
                case 192 { size := 24 }
                case 200 { size := 25 }
                case 208 { size := 26 }
                case 216 { size := 27 }
                case 224 { size := 28 }
                case 232 { size := 29 }
                case 240 { size := 30 }
                case 248 { size := 31 }
                case 256 { size := 32 }
                default  { size := 32 }
        }

    }
    
    function sizeOfUint(uint16 _postfix) internal pure  returns(uint size){
        return sizeOfInt(_postfix);
    }

    function sizeOfAddress() internal pure  returns(uint8){
        return 20; 
    }
    
    function sizeOfBool() internal pure  returns(uint8){
        return 1; 
    }
    

}

contract TypesToBytes {
 
    function TypesToBytes() internal {
        
    }
    function addressToBytes(uint _offst, address _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    }

    function bytes32ToBytes(uint _offst, bytes32 _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
            mstore(add(add(_output, _offst),32), add(_input,32))
        }
    }
    
    function boolToBytes(uint _offst, bool _input, bytes memory _output) internal pure {
        uint8 x = _input == false ? 0 : 1;
        assembly {
            mstore(add(_output, _offst), x)
        }
    }
    
    function stringToBytes(uint _offst, bytes memory _input, bytes memory _output) internal {
        uint256 stack_size = _input.length / 32;
        if(_input.length % 32 > 0) stack_size++;
        
        assembly {
            let index := 0
            stack_size := add(stack_size,1) 
        loop:
            
            mstore(add(_output, _offst), mload(add(_input,mul(index,32))))
            _offst := sub(_offst , 32)
            index := add(index ,1)
            jumpi(loop , lt(index,stack_size))
        }
    }

    function intToBytes(uint _offst, int _input, bytes memory  _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    } 
    
    function uintToBytes(uint _offst, uint _input, bytes memory _output) internal pure {

        assembly {
            mstore(add(_output, _offst), _input)
        }
    }   

}

contract Seriality is BytesToTypes, TypesToBytes, SizeOf {

    function Seriality() public {

    }
}

contract TimedEscrow is ContractReceiver, Seriality {

    using Array256Lib for uint256[];

    struct Transaction {
        uint256 value;
        address to_address;
        uint256 time;
        bool valid;  
        bool executed;  
    }

    Token tokContract;
    address owner;

    Transaction[] transactions;

    mapping(address => uint256[]) transactions_of;

     
    event addingTransaction(uint256 value, address addr, uint256 time, bool valid, bool executed, uint index);
    event voidingTransaction(uint256 index);


    constructor(address _tokContract) public {
        tokContract = Token(_tokContract);
        owner = msg.sender;
    }

    function addTransaction(Transaction transaction) private {
        transactions.push(transaction);
        transactions_of[transaction.to_address].push(transactions.length - 1);
        emit addingTransaction(transaction.value, transaction.to_address, transaction.time, transaction.valid, transaction.executed, transactions.length - 1);
    }

    function transferOwnership(address tbo){
        require(msg.sender == owner, 'Unauthorized');
        owner = tbo;
    }

     
     

    function voidTransaction(uint256 transaction_id){
        require(
            msg.sender == transactions[transaction_id].to_address
            && !transactions[transaction_id].executed
        && transactions[transaction_id].valid
        );
        transactions[transaction_id].valid = false;
        tokContract.transfer(owner, transactions[transaction_id].value);
        emit voidingTransaction(transaction_id);
    }

    function getTransactionIdsOf(address to_address) public view returns (uint[]){
        return transactions_of[to_address];
    }

    function getTransaction(uint256 transaction_id) public view returns (uint256 value, address to_address, uint256 time, bool valid, bool executed){
        Transaction memory t = transactions[transaction_id];
        value = t.value;
        to_address = t.to_address;
        time = t.time;
        valid = t.valid;
        executed = t.executed;
        return;
    }

    function performTransaction(uint256 transaction_id){
        Transaction tbp = transactions[transaction_id];
        require(now > tbp.time && tbp.valid && !tbp.executed, 'Invalid transaction data');
        tbp.executed = true;
        transactions[transaction_id] = tbp;
        tokContract.transfer(tbp.to_address, tbp.value);
    }

    function transactionStructFromBytesSeriality(bytes data) internal pure returns (Transaction){
        Transaction memory t;
        uint offset = 128;
        bytes memory buffer = new bytes(128);

        t.value = bytesToUint256(offset, data);
        offset -= sizeOfUint(256);

        t.to_address = bytesToAddress(offset, data);
        offset -= sizeOfAddress();

        t.time = bytesToUint256(offset, data);
        offset -= sizeOfUint(256);

        t.valid = bytesToBool(offset, data);
        offset -= sizeOfBool();

        t.executed = bytesToBool(offset, data);
        offset -= sizeOfBool();
        return t;

    }

    function transactionStructToBytesSeriality(Transaction t) private pure returns (bytes){
        bytes memory buffer = new bytes(128);
        uint offset = 128;

        uintToBytes(offset, t.value, buffer);
        offset -= sizeOfUint(256);

        addressToBytes(offset, t.to_address, buffer);
        offset -= sizeOfAddress();

        uintToBytes(offset, t.time, buffer);
        offset -= sizeOfUint(256);

        boolToBytes(offset, t.valid, buffer);
        offset -= sizeOfBool();

        boolToBytes(offset, t.executed, buffer);
        offset -= sizeOfBool();
        return buffer;
    }

    function transactionRawToBytes(uint256 value, address to_address, uint256 time, bool valid, bool executed) public pure returns (bytes){
        Transaction memory t;
        t.value = value;
        t.to_address = to_address;
        t.time = time;
        t.valid = valid;
        t.executed = executed;
        return transactionStructToBytesSeriality(t);
    }

    function tokenFallback(address _from, uint _value, bytes _data) public {
        require(_value > 0, 'No transaction was added because value was zero');
        Transaction memory transaction = transactionStructFromBytesSeriality(_data);
        require(transaction.value == _value, 'Token sent were not equal to token to store');
        require(transaction.time > now, 'Time was in the past');
        require(transaction.valid == true && transaction.executed == false, 'Transaction data is invalid');
        addTransaction(transaction);
    }

    function rescheduleTransaction(uint256 transaction_id, uint256 newtime) public {
        require(msg.sender == owner);
        require(!transactions[transaction_id].executed
        && transactions[transaction_id].valid
        && transactions[transaction_id].time > newtime);
        transactions[transaction_id].time = newtime;
    }

}