 

pragma solidity ^0.4.18;

contract WorldBetToken {
     
    string public name = "World Bet Lottery Tickets";

     
    string public symbol = "WBT";

     
    uint public decimals = 0;

    mapping(uint => uint) private userBalanceOf;                 
    bool public stopped = false;

     
    struct Country {
        uint user;  
        uint balance;  
    }

     
    uint public WINNER_COUNTRY_CODE = 0;

    mapping(uint => bool) private countryIsPlaying;

     
    mapping(uint => Country[]) public users;        


     
    mapping(uint => uint[]) public countries;        

     
    uint[] public jackpotUsers;

     
    uint[] activeCountries;

     
    mapping(uint => bool) isJackpotEligible;

     
    mapping(uint => uint) jackpotLocation;

     
    uint public JACKPOT_WINNER = 0;

    uint jackpotMaxCap = 100;

    uint public totalSupply = 0;

    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert(!stopped);
        _;
    }

    modifier valAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function WorldBetToken() public {
        owner = msg.sender;
        countryIsPlaying[1] = true;
         
        countryIsPlaying[2] = true;
         
        countryIsPlaying[3] = true;
         
        countryIsPlaying[4] = true;
         
        countryIsPlaying[5] = true;
         
        countryIsPlaying[6] = true;
         
        countryIsPlaying[7] = true;
         
        countryIsPlaying[8] = true;
         
        countryIsPlaying[9] = true;
         
        countryIsPlaying[10] = true;
         
        countryIsPlaying[11] = true;
         
        countryIsPlaying[12] = true;
         
        countryIsPlaying[13] = true;
         
        countryIsPlaying[14] = true;
         
        countryIsPlaying[15] = true;
         
        countryIsPlaying[16] = true;
         
        countryIsPlaying[17] = true;
         
        countryIsPlaying[18] = true;
         
        countryIsPlaying[19] = true;
         
        countryIsPlaying[20] = true;
         
        countryIsPlaying[21] = true;
         
        countryIsPlaying[22] = true;
         
        countryIsPlaying[23] = true;
         
        countryIsPlaying[24] = true;
         
        countryIsPlaying[25] = true;
         
        countryIsPlaying[26] = true;
         
        countryIsPlaying[27] = true;
         
        countryIsPlaying[28] = true;
         
        countryIsPlaying[29] = true;
         
        countryIsPlaying[30] = true;
         
        countryIsPlaying[31] = true;
         
        countryIsPlaying[32] = true;
         
    }

    function giveBalance(uint country, uint user, uint value) public isRunning returns (bool success) {
        require(countryIsPlaying[country]);
        require(WINNER_COUNTRY_CODE == 0);


         
        userBalanceOf[user] += value;


        countries[country].push(user);

        users[user].push(Country(user, value));

        if (userBalanceOf[user] >= jackpotMaxCap && !isJackpotEligible[user]) {
            jackpotUsers.push(user);
            jackpotLocation[user] = jackpotUsers.length - 1;
        }

         
        totalSupply += value;

         
        Transfer(0x0, user, value);
        return true;
    }

    function installWinner(uint country) public {
        require(WINNER_COUNTRY_CODE == 0);
        require(countryIsPlaying[country]);
        WINNER_COUNTRY_CODE = country;
        WinnerInstalled(WINNER_COUNTRY_CODE);
    }

    function removeCountry(uint country) public {
        countryIsPlaying[country] = false;
        CountryRemoved(country);
    }

    function playJackpot() public {
        require(JACKPOT_WINNER == 0);
        if (jackpotUsers.length >= 2) {
            uint nonce = jackpotUsers.length;
            uint max = jackpotUsers.length - 1;
            uint randomNumber = uint(keccak256(nonce)) % max;
            JACKPOT_WINNER = jackpotUsers[randomNumber];
        } else {
            JACKPOT_WINNER = jackpotUsers[0];
        }
    }

    function winnerList() view public returns (uint[]){
        return countries[WINNER_COUNTRY_CODE];
    }

    event Transfer(address indexed _from, uint indexed _to, uint _value);
    event CountryRemoved(uint indexed country);
    event WinnerInstalled(uint indexed country);
}