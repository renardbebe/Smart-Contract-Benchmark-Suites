 

pragma solidity ^0.4.25;

 

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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool   );
    function getCurrentReward(address  ) external pure returns( uint256   );
    function withdrawReward(address  ) external;
    function fallback() external payable;
}
contract CrryptoWallet {
	using SafeMath for uint256;

	address public administrator;
    uint256 public totalContractMiniGame = 0;

    mapping(address => bool)   public miniGames; 
    mapping(uint256 => address) public miniGameAddress;

    modifier onlyContractsMiniGame() 
    {
        require(miniGames[msg.sender] == true);
        _;
    }
    event Withdraw(address _addr, uint256 _eth);

    constructor() public {
        administrator = msg.sender;
    }
    function () public payable
    {
        
    }
     
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function isWalletContract() public pure returns(bool)
    {
        return true;
    }
    function upgrade(address addr) public 
    {
        require(administrator == msg.sender);

        selfdestruct(addr);
    }
     
    function setupMiniGame( uint256  , uint256  ) public
    {
    }
     
     
     
    function setContractsMiniGame( address _addr ) public  
    {
        require(administrator == msg.sender);

        MiniGameInterface MiniGame = MiniGameInterface( _addr );

        if ( miniGames[_addr] == false ) {
            miniGames[_addr] = true;
            miniGameAddress[totalContractMiniGame] = _addr;
            totalContractMiniGame = totalContractMiniGame + 1;
        }
    }
     
    function removeContractMiniGame(address _addr) public 
    {
        require(administrator == msg.sender);

        miniGames[_addr] = false;
    }
   
    
     
     
     
    function getCurrentReward(address _addr) public view returns(uint256 _currentReward)
    {
        for(uint256 idx = 0; idx < totalContractMiniGame; idx++) {
            if (miniGames[miniGameAddress[idx]] == true) {
                MiniGameInterface MiniGame = MiniGameInterface(miniGameAddress[idx]);
                _currentReward += MiniGame.getCurrentReward(_addr);
            }
        }
    }

    function withdrawReward() public 
    {
        for(uint256 idx = 0; idx < totalContractMiniGame; idx++) {
            if (miniGames[miniGameAddress[idx]] == true) {
                MiniGameInterface MiniGame = MiniGameInterface(miniGameAddress[idx]);
                MiniGame.withdrawReward(msg.sender);
            }
        }
    }
}