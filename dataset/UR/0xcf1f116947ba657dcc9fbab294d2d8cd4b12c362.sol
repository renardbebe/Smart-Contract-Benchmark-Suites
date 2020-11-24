 

pragma solidity 0.4.24;

 

 
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

 

contract database {

     
    using SafeMath for uint256;

     
    struct participant {
        address eth_address;  
        uint256 topl_address;  
        uint256 arbits;  
        uint256 num_of_pro_rata_tokens_alloted;
        bool arbits_kyc_whitelist;  
        uint8 num_of_uses;
    }

     
     
    mapping(address => bool) public sale_owners;
    mapping(address => bool) public owners;
    mapping(address => bool) public masters;
    mapping(address => bool) public kycers;

     
    mapping(address => participant) public participants;
    address[] public participant_keys;

     
    bool public arbits_presale_open = false;  
    bool public iconiq_presale_open = false;  
    bool public arbits_sale_open = false;  

     
    uint256 public pre_kyc_bonus_denominator;
    uint256 public pre_kyc_bonus_numerator;
    uint256 public pre_kyc_iconiq_bonus_denominator;
    uint256 public pre_kyc_iconiq_bonus_numerator;

    uint256 public contrib_arbits_min;
    uint256 public contrib_arbits_max;

     
    uint256 public presale_arbits_per_ether;         
    uint256 public presale_iconiq_arbits_per_ether;  
    uint256 public presale_arbits_total = 18000000;
    uint256 public presale_arbits_sold;

     
    uint256 public sale_arbits_per_ether;
    uint256 public sale_arbits_total;
    uint256 public sale_arbits_sold;

     
    constructor() public {
        owners[msg.sender] = true;
    }

     
    function add_owner(address __subject) public only_owner {
        owners[__subject] = true;
    }

    function remove_owner(address __subject) public only_owner {
        owners[__subject] = false;
    }

    function add_master(address _subject) public only_owner {
        masters[_subject] = true;
    }

    function remove_master(address _subject) public only_owner {
        masters[_subject] = false;
    }

    function add_kycer(address _subject) public only_owner {
        kycers[_subject] = true;
    }

    function remove_kycer(address _subject) public only_owner {
        kycers[_subject] = false;
    }

     
    modifier log_participant_update(address __eth_address) {
        participant_keys.push(__eth_address);  
        _;
    }

    modifier only_owner() {
        require(owners[msg.sender]);
        _;
    }

    modifier only_kycer() {
        require(kycers[msg.sender]);
        _;
    }

    modifier only_master_or_owner() {
        require(masters[msg.sender] || owners[msg.sender]);
        _;
    }

     
     
     
    function get_sale_owner(address _a) public view returns(bool) {
        return sale_owners[_a];
    }
    
    function get_contrib_arbits_min() public view returns(uint256) {
        return contrib_arbits_min;
    }

    function get_contrib_arbits_max() public view returns(uint256) {
        return contrib_arbits_max;
    }

    function get_pre_kyc_bonus_numerator() public view returns(uint256) {
        return pre_kyc_bonus_numerator;
    }

    function get_pre_kyc_bonus_denominator() public view returns(uint256) {
        return pre_kyc_bonus_denominator;
    }

    function get_pre_kyc_iconiq_bonus_numerator() public view returns(uint256) {
        return pre_kyc_iconiq_bonus_numerator;
    }

    function get_pre_kyc_iconiq_bonus_denominator() public view returns(uint256) {
        return pre_kyc_iconiq_bonus_denominator;
    }

    function get_presale_iconiq_arbits_per_ether() public view returns(uint256) {
        return (presale_iconiq_arbits_per_ether);
    }

    function get_presale_arbits_per_ether() public view returns(uint256) {
        return (presale_arbits_per_ether);
    }

    function get_presale_arbits_total() public view returns(uint256) {
        return (presale_arbits_total);
    }

    function get_presale_arbits_sold() public view returns(uint256) {
        return (presale_arbits_sold);
    }

    function get_sale_arbits_per_ether() public view returns(uint256) {
        return (sale_arbits_per_ether);
    }

    function get_sale_arbits_total() public view returns(uint256) {
        return (sale_arbits_total);
    }

    function get_sale_arbits_sold() public view returns(uint256) {
        return (sale_arbits_sold);
    }

     
    function set_sale_owner(address _a, bool _v) public only_master_or_owner {
        sale_owners[_a] = _v;
    }

    function set_contrib_arbits_min(uint256 _v) public only_master_or_owner {
        contrib_arbits_min = _v;
    }

    function set_contrib_arbits_max(uint256 _v) public only_master_or_owner {
        contrib_arbits_max = _v;
    }

    function set_pre_kyc_bonus_numerator(uint256 _v) public only_master_or_owner {
        pre_kyc_bonus_numerator = _v;
    }

    function set_pre_kyc_bonus_denominator(uint256 _v) public only_master_or_owner {
        pre_kyc_bonus_denominator = _v;
    }

    function set_pre_kyc_iconiq_bonus_numerator(uint256 _v) public only_master_or_owner {
        pre_kyc_iconiq_bonus_numerator = _v;
    }

    function set_pre_kyc_iconiq_bonus_denominator(uint256 _v) public only_master_or_owner {
        pre_kyc_iconiq_bonus_denominator = _v;
    }

    function set_presale_iconiq_arbits_per_ether(uint256 _v) public only_master_or_owner {
        presale_iconiq_arbits_per_ether = _v;
    }

    function set_presale_arbits_per_ether(uint256 _v) public only_master_or_owner {
        presale_arbits_per_ether = _v;
    }

    function set_presale_arbits_total(uint256 _v) public only_master_or_owner {
        presale_arbits_total = _v;
    }

    function set_presale_arbits_sold(uint256 _v) public only_master_or_owner {
        presale_arbits_sold = _v;
    }

    function set_sale_arbits_per_ether(uint256 _v) public only_master_or_owner {
        sale_arbits_per_ether = _v;
    }

    function set_sale_arbits_total(uint256 _v) public only_master_or_owner {
        sale_arbits_total = _v;
    }

    function set_sale_arbits_sold(uint256 _v) public only_master_or_owner {
        sale_arbits_sold = _v;
    }

     
     
    function get_participant(address _a) public view returns(
        address,
        uint256,
        uint256,
        uint256,
        bool,
        uint8
    ) {
        participant storage subject = participants[_a];
        return (
            subject.eth_address,
            subject.topl_address,
            subject.arbits,
            subject.num_of_pro_rata_tokens_alloted,
            subject.arbits_kyc_whitelist,
            subject.num_of_uses
        );
    }

    function get_participant_num_of_uses(address _a) public view returns(uint8) {
        return (participants[_a].num_of_uses);
    }

    function get_participant_topl_address(address _a) public view returns(uint256) {
        return (participants[_a].topl_address);
    }

    function get_participant_arbits(address _a) public view returns(uint256) {
        return (participants[_a].arbits);
    }

    function get_participant_num_of_pro_rata_tokens_alloted(address _a) public view returns(uint256) {
        return (participants[_a].num_of_pro_rata_tokens_alloted);
    }

    function get_participant_arbits_kyc_whitelist(address _a) public view returns(bool) {
        return (participants[_a].arbits_kyc_whitelist);
    }

     
    function set_participant(
        address _a,
        uint256 _ta,
        uint256 _arbits,
        uint256 _prta,
        bool _v3,
        uint8 _nou
    ) public only_master_or_owner log_participant_update(_a) {
        participant storage subject = participants[_a];
        subject.eth_address = _a;
        subject.topl_address = _ta;
        subject.arbits = _arbits;
        subject.num_of_pro_rata_tokens_alloted = _prta;
        subject.arbits_kyc_whitelist = _v3;
        subject.num_of_uses = _nou;
    }

    function set_participant_num_of_uses(
        address _a,
        uint8 _v
    ) public only_master_or_owner log_participant_update(_a) {
        participants[_a].num_of_uses = _v;
    }

    function set_participant_topl_address(
        address _a,
        uint256 _ta
    ) public only_master_or_owner log_participant_update(_a) {
        participants[_a].topl_address = _ta;
    }

    function set_participant_arbits(
        address _a,
        uint256 _v
    ) public only_master_or_owner log_participant_update(_a) {
        participants[_a].arbits = _v;
    }

    function set_participant_num_of_pro_rata_tokens_alloted(
        address _a,
        uint256 _v
    ) public only_master_or_owner log_participant_update(_a) {
        participants[_a].num_of_pro_rata_tokens_alloted = _v;
    }

    function set_participant_arbits_kyc_whitelist(
        address _a,
        bool _v
    ) public only_kycer log_participant_update(_a) {
        participants[_a].arbits_kyc_whitelist = _v;
    }


     
     

     
    function get_iconiq_presale_open() public view only_master_or_owner returns(bool) {
        return iconiq_presale_open;
    }

    function get_arbits_presale_open() public view only_master_or_owner returns(bool) {
        return arbits_presale_open;
    }

    function get_arbits_sale_open() public view only_master_or_owner returns(bool) {
        return arbits_sale_open;
    }

     
    function set_iconiq_presale_open(bool _v) public only_master_or_owner {
        iconiq_presale_open = _v;
    }

    function set_arbits_presale_open(bool _v) public only_master_or_owner {
        arbits_presale_open = _v;
    }

    function set_arbits_sale_open(bool _v) public only_master_or_owner {
        arbits_sale_open = _v;
    }

}