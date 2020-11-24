 

 

pragma solidity >= 0.5.0 < 0.6.0;


 


 
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract VONNI is IERC20 {
    string public name = "VONNICON";
    string public symbol = "VONNI";
    uint8 public decimals = 18;
    
    uint256 partnerAmount;
    uint256 marketingAmount;
    uint256 pomAmount;
    uint256 companyAmount;
    uint256 kmjAmount;
    uint256 kdhAmount;
    uint256 saleAmount;

    
    uint256 _totalSupply;
    mapping(address => uint256) balances;

    address public owner;
    address public partner;
    address public marketing;
    address public pom;
    address public company;
    address public kmj;
    address public kdh;
    address public sale;

    address public marker1;
    address public marker2;
    address public marker3;
    address public marker4;
    address public marker5;
    address public marker6;

    IERC20 private _marker1;
    IERC20 private _marker2;
    IERC20 private _marker3;
    IERC20 private _marker4;
    IERC20 private _marker5;
    IERC20 private _marker6;

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor() public {
        owner   = msg.sender;
        partner = 0x0182bBbd17792B612a90682486FCfc6230D0C87a;
        marketing = 0xE818EBEc8C8174049748277b8d0Dc266b1A9962A;
        pom = 0x423325e29C8311217994B938f76fDe0040326B2A;
        company = 0xfec56eFB1a87BB15da444fDaFFB384572aeceE17;
        kmj = 0xC350493EC241f801901d1E74372B386c3e6E5703;
        kdh = 0x7fACD833AD981Fbbfbe93b071E8c491A47cBC8Fa;
        sale = 0xeab7Af104c4156Adb800E1Cd3ca35d358c6145b3;
        
        marker1 = 0xf54343AB797C9647a2643a037E16E8eF32b9Eb87;
        marker2 = 0x31514548CbEAD19EEdc7977AC3cc52b8aF1a6FE2;
        marker3 = 0xa4f5947Ee4EDD96dc8EAf2d9E6149B66E6558C14;
        marker4 = 0x4908730237360Df173b0a870b7208B08EC26Bd13;
        marker5 = 0x65b87739bac3987DBA6e7b04cD8ECeaB94b7Ea3d;
        marker6 = 0x423B9EDD4b9D82bAc47A76efB5381EEDa4068581;
        
        partnerAmount   = toWei( 250000000);
        marketingAmount = toWei( 500000000);
        pomAmount       = toWei(1500000000);
        companyAmount   = toWei(1150000000);
        kmjAmount       = toWei( 100000000);
        kdhAmount       = toWei( 250000000);
        saleAmount      = toWei(1250000000);
        _totalSupply    = toWei(5000000000);   
        
        
         _marker1 = IERC20(marker1);
         _marker2 = IERC20(marker2);
         _marker3 = IERC20(marker3);
         _marker4 = IERC20(marker4);
         _marker5 = IERC20(marker5);
         _marker6 = IERC20(marker6);



        require(_totalSupply == partnerAmount + marketingAmount + pomAmount + companyAmount + kmjAmount + kdhAmount + saleAmount );
        
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, balances[owner]);
        
        transfer(partner, partnerAmount);
        transfer(marketing, marketingAmount);
        transfer(pom, pomAmount);
        transfer(company, companyAmount);
        transfer(kmj, kmjAmount);
        transfer(kdh, kdhAmount);
        transfer(sale, saleAmount);


        require(balances[owner] == 0);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address who) public view returns (uint256) {
        return balances[who];
    }
    
    function transfer(address to, uint256 value) public returns (bool success) {
         

        uint256 basis_timestamp1 = now - 1577836800 + 2592000; 
        uint256 basis_timestamp2 = now - 1580515200 + 2592000; 
        uint256 basis_timestamp3 = now - 1583020800 + 2592000; 
        uint256 basis_timestamp4 = now - 1585699200 + 2592000; 
        uint256 basis_timestamp5 = now - 1588291200 + 2592000; 
        uint256 basis_timestamp6 = now - 1590969600 + 2592000; 

        if ( _marker1.balanceOf(msg.sender) > 0 && now < 1577836800 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp1 / (2592000);
            uint256 allowance = (_marker1.balanceOf(msg.sender)) - ((_marker1.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }


        if ( _marker2.balanceOf(msg.sender) > 0 && now < 1580515200 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp2 / (2592000);
            uint256 allowance = (_marker2.balanceOf(msg.sender)) - ((_marker2.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }


        if ( (_marker3.balanceOf(msg.sender)) > 0 && now < 1583020800 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp3 / (2592000);
            uint256 allowance = (_marker3.balanceOf(msg.sender)) - ((_marker3.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }


        if ( (_marker4.balanceOf(msg.sender)) > 0 && now < 1585699200 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp4 / (2592000);
            uint256 allowance = (_marker4.balanceOf(msg.sender)) - ((_marker4.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }

        if ( (_marker5.balanceOf(msg.sender)) > 0 && now < 1588291200 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp5 / (2592000);
            uint256 allowance = (_marker5.balanceOf(msg.sender)) - ((_marker5.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }

        if ( (_marker6.balanceOf(msg.sender)) > 0 && now < 1590969600 + 86400 * 30 * 20) {
            uint256 past_month = basis_timestamp6 / (2592000);
            uint256 allowance = (_marker6.balanceOf(msg.sender)) - ((_marker6.balanceOf(msg.sender)) * past_month / 20);
            
            require( balances[msg.sender] - value >= allowance );
        }



        require(msg.sender != to);
        require(value > 0);
        
        require( balances[msg.sender] >= value );
        require( balances[to] + value >= balances[to] );

        if (to == address(0) || to == address(0x1) || to == address(0xdead)) {
             _totalSupply -= value;
        }

        balances[msg.sender] -= value;
        balances[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function burnCoins(uint256 value) public {
        require(balances[msg.sender] >= value);
        require(_totalSupply >= value);
        
        balances[msg.sender] -= value;
        _totalSupply -= value;

        emit Transfer(msg.sender, address(0), value);
    }


     

    function toWei(uint256 value) private view returns (uint256) {
        return value * (10 ** uint256(decimals));
    }
}