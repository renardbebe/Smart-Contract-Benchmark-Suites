 

pragma solidity ^0.5.7;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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
  address public manager;
  address public ownerWallet;

  constructor() public {
    owner = 0x371A6671c799a6F25c17368eB81A32fA98C967E2;
    manager = 0x371A6671c799a6F25c17368eB81A32fA98C967E2;
    ownerWallet = 0x371A6671c799a6F25c17368eB81A32fA98C967E2;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner");
    _;
  }

  modifier onlyOwnerOrManager() {
     require((msg.sender == owner)||(msg.sender == manager), "only for owner or manager");
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

  function setManager(address _manager) public onlyOwnerOrManager {
      manager = _manager;
  }
}

contract CryptoLights is Ownable {

    event rLE(address indexed _u, address indexed _r, uint _t);
    event bLE(address indexed _u, uint _l, uint _t);
    event gME(address indexed _u, address indexed _r, uint _l, uint _t);
    event lME(address indexed _u, address indexed _r, uint _l, uint _t);
    event bRE(address indexed _u, uint _l, uint _t);
    event lRE(address indexed _u, uint _l,uint _t);
    event dE(address indexed _u,uint _v,uint _t);
    event wE(address indexed _u,uint _v,uint _t);
    mapping (uint => uint) public LP;
    mapping (uint => uint) public TRS;
    uint RLM = 3;
    uint L = 180 days;
    uint public T_1 = 10;
    uint public T_2 = 30;
    uint public T_3 = 70;
    uint public T_4 = 150;
    uint public T_5 = 500;
    struct US {
        bool x;
        uint a;
        uint b;
        address[] c;
        mapping (uint => uint) d;
        mapping (address => uint) e;
        mapping (uint => bool) f;
    }
    mapping (address => US) public us;
    mapping (uint => address) public uL;
    uint public g = 0;
    constructor() public {
        LP[1] = 0.1 ether;
        LP[2] = 0.2 ether;
        LP[3] = 0.6 ether;
        LP[4] = 1.8 ether;
        LP[5] = 5.4 ether;
        TRS[1] = 0.1 ether;
        TRS[2] = 0.25 ether;
        TRS[3] = 0.55 ether;
        TRS[4] = 1.5 ether;
        TRS[5] = 5 ether;
        US memory uS;
        g++;
        uS = US({
            x : true,
            a : g,
            b : 0,
            c : new address[](0)
        });
        us[ownerWallet] = uS;
        uL[g] = ownerWallet;
        us[ownerWallet].d[1] = 77777777777;
        us[ownerWallet].d[2] = 77777777777;
        us[ownerWallet].d[3] = 77777777777;
        us[ownerWallet].d[4] = 77777777777;
        us[ownerWallet].d[5] = 77777777777;
    }

    function () external payable {
        uint level;
        if(msg.value == LP[1]){
            level = 1;
        }else if(msg.value == LP[2]){
            level = 2;
        }else if(msg.value == LP[3]){
            level = 3;
        }else if(msg.value == LP[4]){
            level = 4;
        }else if(msg.value == LP[5]){
            level = 5;
        }else {
            revert('Incorrect Value send');
        }
        if(us[msg.sender].x){
            funcG(level);
        } else if(level == 1) {
            uint refId = 0;
            address referrer = bTA(msg.data);

            if (us[referrer].x){
                refId = us[referrer].a;
            } else {
                revert('Incorrect referrer');
            }
            funcA(refId);
        } else {
            revert("Please buy first level");
        }
    }
    function funcA(uint _l) public payable {
        uint _b = _l;
        require(!us[msg.sender].x, 'User exist');
        require(_b > 0 && _b <= g, 'Incorrect referrer Id');
        require(msg.value==LP[1], 'Incorrect Value');
        if(us[uL[_b]].c.length >= RLM)
        {
            _b = us[funcIV4(uL[_b])].a;
        }
        US memory uS;
        g++;
        uS = US({
            x : true,
            a : g,
            b : _b,
            c : new address[](0)
        });
        us[msg.sender] = uS;
        uL[g] = msg.sender;
        us[msg.sender].d[1] = now + L;
        us[msg.sender].d[2] = 0;
        us[msg.sender].d[3] = 0;
        us[msg.sender].d[4] = 0;
        us[msg.sender].d[5] = 0;
        us[uL[_b]].c.push(msg.sender);
        funcH(1, msg.sender);
        emit rLE(msg.sender, uL[_b], now);
        funcB(uL[_b],msg.sender);
    }
    function funcB(address _r,address _u) private {
        if (us[_r].x){
            us[_r].e[_u] += 1;
            funcC(_r);
            funcB(uL[us[_r].b],_r);
        }
    } 
    function funcC(address _u) private {
        if (us[_u].c.length == 3){
            uint _t1C = us[_u].e[us[_u].c[0]];
            uint _t2C = us[_u].e[us[_u].c[1]];
            uint _t3C = us[_u].e[us[_u].c[2]];
            if (_t1C >= T_1 && _t2C >= T_1 && _t3C >= T_1 && !us[_u].f[0]){
                bool _rs;
                _rs = address(uint160(_u)).send(TRS[1]);
                if (_rs){
                    emit bRE(_u,1,now);
                    us[_u].f[0] = true;
                } else {
                    emit lRE(_u,1,now);
                }
            }
            if (_t1C >= T_2 && _t2C >= T_2 && _t3C >= T_2 && !us[_u].f[1]){
                bool _rs;
                _rs = address(uint160(_u)).send(TRS[2]);
                if (_rs){
                    emit bRE(_u,2,now);
                    us[_u].f[1] = true;
                } else {
                    emit lRE(_u,2,now);
                }
            }
            if (_t1C >= T_3 && _t2C >= T_3 && _t3C >= T_3 && !us[_u].f[2]){
                bool _rs;
                _rs = address(uint160(_u)).send(TRS[3]);
                if (_rs){
                    emit bRE(_u,3,now);
                    us[_u].f[2] = true;
                } else {
                    emit lRE(_u,3,now);
                }
            }
            if (_t1C >= T_4 && _t2C >= T_4 && _t3C >= T_4 && !us[_u].f[3]){
                bool _rs;
                _rs = address(uint160(_u)).send(TRS[4]);
                if (_rs){
                    emit bRE(_u,4,now);
                    us[_u].f[3] = true;
                } else {
                    emit lRE(_u,4,now);
                }
            }
            if (_t1C >= T_5 && _t2C >= T_5 && _t3C >= T_5 && !us[_u].f[4]){
                bool _rs;
                _rs = address(uint160(_u)).send(TRS[5]);
                if (_rs){
                    emit bRE(_u,5,now);
                    us[_u].f[4] = true;
                } else {
                    emit lRE(_u,5,now);
                }
            }
        }
    }
    function funcD() public payable {
        emit dE(msg.sender,msg.value,now);
    }
    function funcE(uint _v) public onlyOwner {
        msg.sender.transfer(_v);
        emit wE(msg.sender,_v,now);
    }
    function funcF(address _u,uint _l) public onlyOwner {
        require(us[_u].x,'User not exist');
        require(_l>1 && _l<=5,'Incorrect level');
        for (uint l = 2; l <= _l;l++){
            us[_u].d[l] = now + L;
        }
    }
    function funcG(uint _l) public payable {
        require(us[msg.sender].x, 'User not exist');

        require(_l>0 && _l<=5,'Incorrect level');

        if(_l == 1){
            require(msg.value==LP[1], 'Incorrect Value');
            us[msg.sender].d[1] += L;
        } else {
            require(msg.value==LP[_l], 'Incorrect Value');

            for(uint l =_l-1; l>0; l-- ){
                require(us[msg.sender].d[l] >= now, 'Buy the previous level');
            }

            if(us[msg.sender].d[_l] == 0){
                us[msg.sender].d[_l] = now + L;
            } else {
                us[msg.sender].d[_l] += L;
            }
        }
        funcH(_l, msg.sender);
        emit bLE(msg.sender, _l, now);
    }
    function funcH(uint _l, address _u) internal {
        address _r;
        address _r1;
        address _r2;
        address _r3;
        address _r4;
        if(_l == 1){
            _r = uL[us[_u].b];
        } else if(_l == 2){
            _r1 = uL[us[_u].b];
            _r = uL[us[_r1].b];
        } else if(_l == 3){
            _r1 = uL[us[_u].b];
            _r2 = uL[us[_r1].b];
            _r = uL[us[_r2].b];
        } else if(_l == 4){
            _r1 = uL[us[_u].b];
            _r2 = uL[us[_r1].b];
            _r3 = uL[us[_r2].b];
            _r = uL[us[_r3].b];
        } else if(_l == 5){
            _r1 = uL[us[_u].b];
            _r2 = uL[us[_r1].b];
            _r3 = uL[us[_r2].b];            
            _r4 = uL[us[_r3].b];
            _r = uL[us[_r4].b];
        }
        if(!us[_r].x){
            _r = uL[1];
        }
        if(us[_r].d[_l] >= now ){
            bool _rs;
            _rs = address(uint160(_r)).send(LP[_l]);
            emit gME(_r, msg.sender, _l, now);
        } else {
            emit lME(_r, msg.sender, _l, now);
            funcH(_l,_r);
        }
    }
    function funcI(address[] memory _arr,uint _count) public view returns (address){
        require(_count <= 6,'No Free Referrer');
        address[] memory _n = new address[](729);
        uint id = 0;
        for (uint i = 0; i < 4;i++){
            for (uint j = 0; j < _arr.length; j++){
                if (i == 3){
                    for (uint l = 0; l < us[_arr[j]].c.length;l++){
                        _n[id] = us[_arr[j]].c[l];
                        id++;
                    }
                } else {
                    if (us[_arr[j]].c.length == i){
                        return _arr[j];
                    }
                }
            }
        }
        address[] memory n = new address[](id);
        for (uint q = 0;q < id;q++){
            n[q] = _n[q];
        }
        return funcI(n,_count+1);
    }
    function funcIV2(address[] memory _arr,uint _count) public view returns (address){
        require(_count <= 6,'No Free Referrer');
        address[] memory _n = new address[](3**(_count+1));
        for (uint i = 0; i < 4;i++){
            for (uint j = 0; j < _arr.length; j++){
                if (i == 3){
                    for (uint l = 0; l < us[_arr[j]].c.length;l++){
                        _n[j+(3**_count)*l] = us[_arr[j]].c[l];
                    }
                } else {
                    if (us[_arr[j]].c.length == i){
                        return _arr[j];
                    }
                }
            }
        }
        return funcIV2(_n,_count+1);
    }
    function funcIV3(address[] memory _arr,uint _count) public view returns (address){
        require(_count <= 6,'No Free Referrer');
        address[] memory _n = new address[](3**(_count+1));
        uint id = 0;
        for (uint i = 0; i < 4;i++){
            if (i == 3){
                for (uint j = 0;j < _arr.length;j++){
                    for (uint k = 0; k < us[_arr[j]].c.length;k++){
                        _n[id] = us[_arr[j]].c[k];
                        id++;
                    }
                }
            } else {
                uint j = 0;
                while(j < 3**(_count-1)){
                    uint k = j;
                    while(k <= _arr.length){
                        if (us[_arr[k]].c.length == i){
                            return _arr[k];
                        }
                        k += 3**_count;
                    }
                    j++;
                }
            }
        }
        return funcIV3(_n,_count+1);
    }
    function funcIV4(address _u) public view returns(address) {
        require(us[_u].x,'User not exist');
        uint[] memory _n = new uint[](3);
        _n[0] = 0;
        _n[1] = 1;
        _n[2] = 2;
        if (us[_u].c.length < 3){
            return _u;
        }
        return funcFR(us[_u].c,_n);
    }
    function funcFR(address[] memory _a,uint[] memory _n) private view returns (address){
        require(_n.length <= 729,'F6');
        address[] memory _na = new address[](3*_a.length);
        uint[] memory _nn = new uint[](3*_n.length);
        for (uint i = 0;i < 3;i++){
            for (uint j = 0;j < _a.length;j++){
                if (us[_a[_n[j]]].c.length == i){
                    return _a[_n[j]];
                }
            }
        }
        for (uint i = 0; i < _a.length;i++){
            for (uint j = 0; j < us[_a[i]].c.length;j++){
                _na[3*i+j] = us[_a[i]].c[j];
            }
        }
        for (uint i = 0;i < 3;i++){
            for (uint j = 0; j < _n.length;j++){
                _nn[_n.length*i+j] = 3*_n[j] + i;
            }
        }
        return funcFR(_na,_nn);
    }
    function vUR(address _u) public view returns(address[] memory) {
        return us[_u].c;
    }
    function vUT(address _u, address _aT) public view returns(uint){
        return us[_u].e[_aT];
    }

    function vULE(address _u, uint _l) public view returns(uint) {
        return us[_u].d[_l];
    }
    function vURS(address _u,uint _r) public view returns(bool){
        return us[_u].f[_r];
    }
    function bTA(bytes memory bys) private pure returns (address  addr ) {
        assembly { 
            addr := mload(add(bys, 20))
        }
    }
}