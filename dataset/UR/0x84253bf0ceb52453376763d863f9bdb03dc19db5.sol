 

pragma solidity ^0.4.19;

 

contract ERC20 {
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function allowance(address owner, address spender) public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
}


contract Ownable {
    address public owner;

    event OwnerChanged(address oldOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != owner && newOwner != address(0x0));
        address oldOwner = owner;
        owner = newOwner;
        OwnerChanged(oldOwner, newOwner);
    }
}

contract HTRToken is ERC20, Ownable {
    string public name = "Henter.ONE";
    string public symbol = "HTR";
    uint8  public decimals = 18;
    uint256 public totalSupply = 10000000 * 10 ** uint256(decimals);

    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => uint256) balances;

    uint256 public forGenesis = 10000 * 10 ** uint256(decimals);

     
    address[] private genesis = [
         

        0x128ceE70aDE62650175fdDB54FAca7CFF889E771,  
        0xc00eDE6A3C3Af974038E13C72cE606dc7a5d19cd,  
        0x9A885391e9ec3774f07c13BBc40F5a6a8dcE8FF4,  
        0x82d76b4D95159989C40fb321D9900c05223e8D18,  
        0x306c0C767fbDEC59d35fCc192d2E4673A38ed4B2,  
        0x3dd1B6c525246E45a9b772b518D54e394561E904,  
        0x5C9A2ff64A142f7F759bD6Da23Bf34ef17B98f8C,  
        0x1B67dbec92033c5Af269f2bf256757d3Ba0A0981,  
        0xfAF3f2bd980B414932cEEd92DA8F83069128B61e,  
        0x316e7b272CA525A32464624Ac1310289B591D503,  
        0x20223226246d76c7a8c131cce0ea8ec8dcc31fb9,  
        0xC1468F3BB75EE510C1c4f23c5a11C99cdac3b016,  
        0xe0794451F52D097Aee80b93702Df87bc38918979,  
        0xB38E680A06990639F25a92aFB5Acc1c8306b6231,  
        0x1B3b15aDEE5D3419FB6Fb1c68E55cAFD9764c85e,  
        0xb8A02E28602cb8B471b5932dcf2998dC81Fc06a8,  
        0x39a79ABF7c6690ec6803aA31d543d2696fbAA49a,  
        0xF570BadF82133bb10079bCDE16D6ee859730c09c,  
        0x3eBe9d0572eCF73852c6496Ce2f17b6c9E82CCA2,  
        0x79807afD93e28c62a6c411edEef1Bef09aF98Df0,  
        0x489404D2edC4721683D5e5442bEEe891d2D997B7,  
        0x2D8cE8360fc132029349dba5D214dc60B47797cc,  
        0x58DBfe9B6AB7a2Eb44e9eb7EbE28Fbfa0a68E5C1,  
        0xc5f412382931C1fE4C156Db0808737b7BfD82599,  
        0xd37e243d39fab6956f652c3b306f640768bd0336,  
        0x407Db4EFc8F1e7764eb61989e8D35E57c8DBA374,  
        0x488d566Abc1910862E71D80786C614b235FF73c6,  
        0xa3aB171fb528C33D52B8413174E7aBcbeFA4D411,  
        0xFBD8caaa7aA8c045a6c149bE62604655cbd6A475,  
        0x149b2A1e359A04b94Db27c8b90Ae1e7c5596774a,  
        0xcDd371C959cc5f37cC54CaC669e5Cb0fc9B27a2C,  
        0x860a53206d1f92A28F61bb80E4025242b53F4A93,  
        0x9BA567ef097df1628eB41564e13E4bcE41Fe168E,  
        0xfe48012b57A02b31715e2b73718bD1dC3823B58d,  
        0x9Ae98B7c2847C0d8C4C2993CD320Efa9AeCb68A4,  
        0x1DE494FE4df057d078132DA62532369F5dEA0184,  
        0x71375ce37ce8494ec13cfecba4ef14876ec086d3,  
        0x1Dab428691F8153584cCabF88CFeF9b8ef5b9B2d,  
        0x34199d6AE4CcC572d869Ee0628d1495936Ec171d,  
        0x1d642F2426177191DA80d15Ea76c71544aad4eae,  
        0x937e6dA7F8750DC2ef6939EBC0025bBC99232602,  
        0xe3429d8af1def8e1ec9b79ed67dafeb0adc9f4dd,  
        0xe748a668D9697623969cB71A8e8D28285E819b45,  
        0x2938BefC1845bEE6d8d02089fB467A781217c8ef,  
        0x20595ae705fDAa7C256AFd64A5150ABFf42E654e,  
        0x87e216d09F855B4e8AA95a14F56583D84eC7af3C,  
        0x6832FE33956cAeB4e96eCAa87f5650218c2618b9,  
        0xc40C6Ff9E4ACF876B22DAFeb2a5F643157E1aCA9,  
        0xfa2355542c73B3501B715fA2Dc41f69aB9260322,  
        0x6a4130F6f5671811912da156c72420b101D9D0A6,  
        0x0eD51eD76536ed6e93d6F7735451cd0de0D9AFF1,  
        0xe52fe0Dfe10b2D8FC300F09074c6CA0BAd2BfeA8,  
        0xC98506F6836684109Fa63e0b637dFCCBb0492707,  
        0x54640F357199a4E9E1b12E249A7Df9B52BEEfd1a,  
        0xA56637FeE8543400cb194f2719dB5b29A5EBf5fe,  
        0x98aEc03f4E7187bE7027B7E0252Be67d5948d26B,  
        0x33627397E2b4f60e33a1f5d6AE67f748366a1f76,  
        0x9aDdA31fC7AD44729106DF337d9f5F640D647760,  
        0x476a69456206334cC4E72D9d1cF69037B1Ca58a1,  
        0xfc6952469DFeaA1760f2D1Fb3Ed72ec2A814af06,  
        0x80496576ed1ddc31c6e229d5017b4701c5f25b3d,  
        0x8ce2126557b573CfC3c710f9477fd0c2e1B1050e,  
        0x5997316B8518489D22ba22Fb86526f5Ed3067cBF,  
        0xC18Be4BbB7ef3B8ce97193E5d76Db85EcD0301F3,  
        0x3d5929Fc2a2d0e0Bb6B111DC5DCd9721f8F5F5f9,  
        0x3492adcd9450E475d200A016216Bca26bED2aAED,  
        0xD69ec0676FEB526Dbe59962aa3E97Fe189B0D080,  
        0x2265e08a6b359fa214945bae509b9b5b303d730f,  
        0xdA7B9ee2CF2CeE941BdD747DCe7016ff803AB852,  
        0x188987ae249407094b92fb78788fa9cbf6936e2f,  
        0xaf044c0876ee96a95281dae434a35ee55a97b1ee,  
        0x6e95307e28f7f7f64A7CA02f9bC5AF682d000EdF,  
        0xD7846582Ed6522B04f820A4222936a672e075f2d,  
        0xD097407bE755FFB2d51803f650Db462d1D0CbB1B,  
        0xAD73c0009E472B5867673465174B144A782D8ac2,  
        0x2635DB214a50ABE7F18F45Ad65492f9ffC1778f7,  
        0x3EA6733144659beb00300Cd0789B3683095aE939,  
        0x558b0eb221ddbbd4c2688f90fe0e446ab93e703f,  
        0x5201BEbaC536B68Efe222Ea958Dd0d9Fb4F217f9,  
        0x17cf9c972ACFa11cA9c978A0db6EaF7b3Bf1BD05,  
        0xb35E2Ab1212621c874Cc814064fAff371A1f39e1,  
        0x4ff54B0422e429b36e4AF292734B0c4230C6fA7E,  
        0x6A4b634C28e66F764EA553Cf396239CbD7a3F899,  
        0xDa384F18b8A6e83D45afa4731424f1bD08317d10,  
        0xBc381e9a37493f2AA499aB708b0F9f15B43018E0,  
        0x36D15D03eCc18dfa2876328d9D84DDFD829CE048,  
        0x75b25923Ff3aA9E1F901c1d275ae6378C4A972FE,  
        0xDa1F4BD9DE3DBFAF9582701Bc655BE92E01220D9,  
        0x6C4011fEa1b22a58B015823124903310764Ed87c,  
        0x910f6Bc0402782BBe487FeB66Cd715f2dBc46F02,  
        0xfb50333A9630A53416Ddbcf34f4AaE7DfABDdCC3,  
        0xC51C97344296209b2Ec28b483EADB5fD6522E32e,  
        0x96442cb142b4e36C6bb410e4a4dE60AE49A25EFf,  
        0x2576dcB9E8f26357f4f358C1c0344D6C4b14aC86,  
        0x97BBb08186c79aC4c8A770c42bb21d7bf0B7de4d,  
        0xE1F3fAfa40074F17dF33B5aAF974AC418575df5C,  
        0x0BAbac86D9861A2a4b0Cb6B7b87424F38771535C  

         

         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         


         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
    ];

    uint256 public forOwner = totalSupply - forGenesis * genesis.length;
    function HTRToken() public {
         
        for (uint i = 0; i < genesis.length; i++) {
            balances[genesis[i]] = forGenesis;
        }

         
        balances[msg.sender] = forOwner;
    }

    function thanksAllGenesisUsers() public view returns(address[]) {
        return genesis;
    }

    function airdropForGenesisUsers(address[] _addresses) public onlyOwner {
        require(balances[msg.sender] > forGenesis * _addresses.length);

        for (uint i = 0; i < _addresses.length; i++) {
            balances[_addresses[i]] = forGenesis;
            genesis.push(_addresses[i]);
        }
        balances[msg.sender] -= forGenesis * _addresses.length;
    }

    function balanceOf(address _owner) public view returns(uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function _transfer(address _from, address _to, uint _value) internal returns(bool) {
        require(_to != 0x0);
        require(balances[_from] >= _value);
        require(balances[_to] + _value > balances[_to]);
        balances[_from] -= _value;
        balances[_to] += _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns(bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns(bool) {
        return _transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns(bool) {
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}