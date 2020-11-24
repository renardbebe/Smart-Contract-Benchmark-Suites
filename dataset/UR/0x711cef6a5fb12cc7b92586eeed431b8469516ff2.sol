 

pragma solidity ^0.5.1;

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

contract Ownable {
    
    address public owner = address(0);
    bool public stoped  = false;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Stoped(address setter ,bool newValue);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier whenNotStoped() {
        require(!stoped);
        _;
    }

    function setStoped(bool _needStoped) public onlyOwner {
        require(stoped != _needStoped);
        stoped = _needStoped;
        emit Stoped(msg.sender,_needStoped);
    }


    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Cmoable is Ownable {
    address public cmo = address(0);

    event CmoshipTransferred(address indexed previousCmo, address indexed newCmo);

    modifier onlyCmo() {
        require(msg.sender == cmo);
        _;
    }

    function renounceCmoship() public onlyOwner {
        emit CmoshipTransferred(cmo, address(0));
        owner = address(0);
    }

    function transferCmoship(address newCmo) public onlyOwner {
        _transferCmoship(newCmo);
    }

    function _transferCmoship(address newCmo) internal {
        require(newCmo != address(0));
        emit CmoshipTransferred(cmo, newCmo);
        cmo = newCmo;
    }
}


contract BaseToken is Ownable, Cmoable {

    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8  public decimals;
    uint256 public totalSupply;
    uint256 public initedSupply = 0;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwnerOrCmo() {
        require(msg.sender == cmo || msg.sender == owner);
        _;
    }

    function _transfer(address _from, address _to, uint256 _value) internal whenNotStoped {
        require(_to != address(0x0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
        emit Transfer(_from, _to, _value);
    }
    
    function _approve(address _spender, uint256 _value) internal whenNotStoped returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        return _approve(_spender, _value);
    }
}







 
contract LockToken is BaseToken {
    struct LockMeta {
        uint256 amount;
        uint256 endtime;
        bool    deleted;
    }

     
    event Locked(uint32 indexed _type, address indexed _who, uint256 _amounts, uint256 _endtimes);
    event Released(uint32 indexed _type, address indexed _who, uint256 _amounts);
     
    mapping (address => mapping(uint32 => uint256)) public lockedAmount;
      
    mapping (address => mapping(uint32 => LockMeta[])) public lockedDetail;

    function _transfer(address _from, address _to, uint _value) internal {
        require(balanceOf[_from] >= _value + lockedAmount[_from][2]);
        super._transfer(_from, _to, _value);
    }

    function lockRelease() public whenNotStoped {
        
        require(lockedAmount[msg.sender][3] != 0);

        uint256 fronzed_released = 0;
        uint256 dynamic_released = 0;

        if ( lockedAmount[msg.sender][0] != 0 )
        {
            for (uint256 i = 0; i < lockedDetail[msg.sender][0].length; i++) {

                LockMeta storage _meta = lockedDetail[msg.sender][0][i];
                if ( !_meta.deleted && _meta.endtime <= now)
                {
                    _meta.deleted = true;
                    fronzed_released = fronzed_released.add(_meta.amount);
                    emit Released(1, msg.sender, _meta.amount);
                }
            }
        }

        if ( lockedAmount[msg.sender][1] != 0 )
        {
            for (uint256 i = 0; i < lockedDetail[msg.sender][1].length; i++) {

                LockMeta storage _meta = lockedDetail[msg.sender][0][i];
                if ( !_meta.deleted && _meta.endtime <= now)
                {
                    _meta.deleted = true;
                    dynamic_released = dynamic_released.add(_meta.amount);
                    emit Released(2, msg.sender, _meta.amount);
                    
                }
            }
        }

        if ( fronzed_released > 0 || dynamic_released > 0 ) {
            lockedAmount[msg.sender][0] = lockedAmount[msg.sender][0].sub(fronzed_released);
            lockedAmount[msg.sender][1] = lockedAmount[msg.sender][1].sub(dynamic_released);
            lockedAmount[msg.sender][2] = lockedAmount[msg.sender][2].sub(dynamic_released).sub(fronzed_released);
        }
    }

     
    function lock(uint32 _type, address _who, uint256[] memory _amounts, uint256[] memory _endtimes) public  onlyOwnerOrCmo {
        require(_amounts.length == _endtimes.length);

        uint256 _total;

        if ( _type == 2 ) {
            if ( lockedDetail[_who][1].length > 0 )
            {
                emit Locked(0, _who, lockedAmount[_who][1], 0);
                delete lockedDetail[_who][1];
            }

            for (uint256 i = 0; i < _amounts.length; i++) {
                _total = _total.add(_amounts[i]);
                lockedDetail[_who][1].push(LockMeta({
                    amount: _amounts[i],
                    endtime: _endtimes[i],
                    deleted:false
                }));
                emit Locked(2, _who, _amounts[i], _endtimes[i]);
            }
            lockedAmount[_who][1] = _total;
            lockedAmount[_who][2] = lockedAmount[_who][0].add(_total);
            return;
        }


        if ( _type == 1 ) {
            if ( lockedDetail[_who][0].length > 0 )
            {
                revert();
            }

            for (uint256 i = 0; i < _amounts.length; i++) {
                _total = _total.add(_amounts[i]);
                lockedDetail[_who][0].push(LockMeta({
                    amount: _amounts[i],
                    endtime: _endtimes[i],
                    deleted:false
                }));
                emit Locked(1, _who, _amounts[i], _endtimes[i]);
            }
            lockedAmount[_who][0] = _total;
            lockedAmount[_who][2] = lockedAmount[_who][1].add(_total);
            return;
        }

        if ( _type == 0 ) {
            lockedAmount[_who][2] = lockedAmount[_who][2].sub(lockedAmount[_who][1]);
            emit Locked(0, _who, lockedAmount[_who][1], 0);
            delete lockedDetail[_who][1];
            
        }
    }
}

contract Proxyable is BaseToken{

    mapping (address => bool) public disabledProxyList;

    function enableProxy() public whenNotStoped {

        disabledProxyList[msg.sender] = false;
    }

    function disableProxy() public whenNotStoped{
        disabledProxyList[msg.sender] = true;
    }


    function proxyTransferFrom(address _from, address _to, uint256 _value) public onlyOwnerOrCmo returns (bool success) {
        
        require(!disabledProxyList[_from]);
        super._transfer(_from, _to, _value);
        return true;
    }

  
}

 

contract CustomToken is BaseToken,LockToken,Proxyable {

    constructor() public {
        
  
        totalSupply  = 825000000000000;
        initedSupply = 825000000000000;
        name = 'YourLuckyChain';
        symbol = 'YLC';
        decimals = 6;
        balanceOf[0x4d0f988ab584890EA38Ec10402012A8F352B7F6A] = 825000000000000;
        emit Transfer(address(0), 0x4d0f988ab584890EA38Ec10402012A8F352B7F6A, 825000000000000);

         
        owner = 0xbC8e1AcA830A37646cEDEb14c7158F3F1529C909;
        cmo   = 0xA3A2B7d2Cb75D53FfAF710824a51a4B3cF30e9D1;
        




    }

}