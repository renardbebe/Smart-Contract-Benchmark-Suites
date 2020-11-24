 

pragma solidity ^0.4.18;

 
library SafeMath {

     
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

 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
    address public owner;
    address public systemAcc;  

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlySys() {
        require(systemAcc !=address(0) && msg.sender == systemAcc);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
contract BasicToken is ERC20Basic, Pausable {
    using SafeMath for uint256;

     
    mapping(address => uint256) freeBalances;
    mapping(address => uint256) frozenBalances;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= freeBalances[msg.sender]);

         
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_value);
        freeBalances[_to] = freeBalances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return freeBalances[_owner] + frozenBalances[_owner];
    }

    function freeBalanceOf(address _owner) public view returns (uint256 balance) {
        return freeBalances[_owner];
    }

    function frozenBalanceOf(address _owner) public view returns (uint256 balance) {
        return frozenBalances[_owner];
    }
}

 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= freeBalances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        freeBalances[_from] = freeBalances[_from].sub(_value);
        freeBalances[_to] = freeBalances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

 
contract CXTCContract is StandardToken {

    string public constant name = "Culture eXchange Token Chain";  
    string public constant symbol = "CXTC";  
    uint8 public constant decimals = 8;  

    uint256 public constant freeSupply = 21000000 * (10 ** uint256(decimals));  
    uint256 public constant frozenSupply = 189000000 * (10 ** uint256(decimals));  

    address[] parterAcc;

    struct ArtInfo {
        string idtReport;
        string evtReport;
        string escReport;
        string regReport;
    }

    mapping (string => ArtInfo) internal artInfos;
    mapping (address => mapping (uint256 => uint256)) public freezeRecord;

    event Freeze(address indexed _addr, uint256 indexed _amount, uint256 indexed _timestamp);
    event Defreeze(address indexed _addr, uint256 indexed _amount, uint256 indexed _timestamp);
    event Release(address indexed _addr, uint256 indexed _amount);
    event SetParter(address indexed _addr, uint256 indexed _amount);
    event SetSysAcc(address indexed _addr);
    event NewArt(string indexed _id);
    event SetArtIdt(string indexed _id, string indexed _idtReport);
    event SetArtEvt(string indexed _id, string indexed _evtReport);
    event SetArtEsc(string indexed _id, string indexed _escReport);
    event SetArtReg(string indexed _id, string indexed _regReport);

     
    function CXTCContract() public {
        owner = msg.sender;
        totalSupply_ = freeSupply + frozenSupply;
        freeBalances[owner] = freeSupply;
        frozenBalances[owner] = frozenSupply;
    }

     
    function setParter(address _parter, uint256 _amount, uint256 _timestamp) public onlyOwner {
        parterAcc.push(_parter);
        frozenBalances[owner] = frozenBalances[owner].sub(_amount);
        frozenBalances[_parter] = frozenBalances[_parter].add(_amount);
        freezeRecord[_parter][_timestamp] = freezeRecord[_parter][_timestamp].add(_amount);
        Freeze(_parter, _amount, _timestamp);
        SetParter(_parter, _amount);
    }

     
    function setSysAcc(address _sysAcc) public onlyOwner returns (bool) {
        systemAcc = _sysAcc;
        SetSysAcc(_sysAcc);
        return true;
    }

     
    function newArt(string _id, string _regReport) public onlySys returns (bool) {
        ArtInfo memory info = ArtInfo({idtReport: "", evtReport: "", escReport: "", regReport: _regReport});
        artInfos[_id] = info;
        NewArt(_id);
        return true;
    }

     
    function getArt(string _id) public view returns (string, string, string, string) {
        ArtInfo memory info = artInfos[_id];
        return (info.regReport, info.idtReport, info.evtReport, info.escReport);
    }

     
    function setArtIdt(string _id, string _idtReport) public onlySys returns (bool) {
        string idtReport = artInfos[_id].idtReport;
        bytes memory idtReportLen = bytes(idtReport);
        if (idtReportLen.length == 0){
            artInfos[_id].idtReport = _idtReport;
            SetArtIdt(_id, _idtReport);
            return true;
        } else {
            return false;
        }
    }

     
    function setArtEvt(string _id, string _evtReport) public onlySys returns (bool) {
        string evtReport = artInfos[_id].evtReport;
        bytes memory evtReportLen = bytes(evtReport);
        if (evtReportLen.length == 0){
            artInfos[_id].evtReport = _evtReport;
            SetArtEvt(_id, _evtReport);
            return true;
        } else {
            return false;
        }
    }

     
    function setArtEsc(string _id, string _escReport) public onlySys returns (bool) {
        string escReport = artInfos[_id].escReport;
        bytes memory escReportLen = bytes(escReport);
        if (escReportLen.length == 0){
            artInfos[_id].escReport = _escReport;
            SetArtEsc(_id, _escReport);
            return true;
        } else {
            return false;
        }
    }

     
    function issue(address _addr, uint256 _amount, uint256 _timestamp) public onlySys returns (bool) {
         
        require(frozenBalances[owner] >= _amount);
        frozenBalances[owner] = frozenBalances[owner].sub(_amount);
        frozenBalances[_addr]= frozenBalances[_addr].add(_amount);
        freezeRecord[_addr][_timestamp] = freezeRecord[_addr][_timestamp].add(_amount);
        Freeze(_addr, _amount, _timestamp);
        return true;
    }

     
    function distribute(address _to, uint256 _amount, uint256 _timestamp, address[] _addressLst, uint256[] _amountLst) public onlySys returns(bool) {
        frozenBalances[_to]= frozenBalances[_to].add(_amount);
        freezeRecord[_to][_timestamp] = freezeRecord[_to][_timestamp].add(_amount);
        for(uint i = 0; i < _addressLst.length; i++) {
            frozenBalances[_addressLst[i]] = frozenBalances[_addressLst[i]].sub(_amountLst[i]);
            Defreeze(_addressLst[i], _amountLst[i], _timestamp);
        }
        Freeze(_to, _amount, _timestamp);
        return true;
    }

     
    function send(address _to, uint256 _amount, uint256 _fee, uint256 _timestamp) public whenNotPaused returns (bool) {
        require(freeBalances[msg.sender] >= _amount);
        require(_amount >= _fee);
        require(_to != address(0));
        uint256 toAmt = _amount.sub(_fee);
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_amount);
        freeBalances[_to] = freeBalances[_to].add(toAmt);
         
        frozenBalances[systemAcc] = frozenBalances[systemAcc].add(_fee);
        freezeRecord[systemAcc][_timestamp] = freezeRecord[systemAcc][_timestamp].add(_fee);
        Transfer(msg.sender, _to, toAmt);
        Freeze(systemAcc, _fee, _timestamp);
        return true;
    }

     
    function freeze(uint256 _amount, uint256 _timestamp) public whenNotPaused returns (bool) {
        require(freeBalances[msg.sender] >= _amount);
        freeBalances[msg.sender] = freeBalances[msg.sender].sub(_amount);
        frozenBalances[msg.sender] = frozenBalances[msg.sender].add(_amount);
        freezeRecord[msg.sender][_timestamp] = freezeRecord[msg.sender][_timestamp].add(_amount);
        Freeze(msg.sender, _amount, _timestamp);
        return true;
    }

     
    function release(address[] _addressLst, uint256[] _amountLst) public onlySys returns (bool) {
        require(_addressLst.length == _amountLst.length);
        for(uint i = 0; i < _addressLst.length; i++) {
            freeBalances[_addressLst[i]] = freeBalances[_addressLst[i]].add(_amountLst[i]);
            frozenBalances[_addressLst[i]] = frozenBalances[_addressLst[i]].sub(_amountLst[i]);
            Release(_addressLst[i], _amountLst[i]);
        }
        return true;
    }

     
    function bonus(uint256 _sum, address[] _addressLst, uint256[] _amountLst) public onlySys returns (bool) {
        require(frozenBalances[systemAcc] >= _sum);
        require(_addressLst.length == _amountLst.length);
        for(uint i = 0; i < _addressLst.length; i++) {
            freeBalances[_addressLst[i]] = freeBalances[_addressLst[i]].add(_amountLst[i]);
            Transfer(systemAcc, _addressLst[i], _amountLst[i]);
        }
        frozenBalances[systemAcc].sub(_sum);
        Release(systemAcc, _sum);
        return true;
    }
}