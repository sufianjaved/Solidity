pragma solidity ^0.6.0;
import "./IERC20.sol";
import "./SafeMath.sol";

contract BCCTokenBuyableExtension is IERC20{
	//Extending Uint256 with SafeMath Library.
    using SafeMath for uint256;

    //mapping to hold balances against EOA accounts
    mapping (address => uint256) private _balances;

    //mapping to hold approved allowance of token to certain address
    //Owner Spender allowance
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) private _contractAmount;
    //the amount of tokens in existence
    uint256 private _totalSupply;

    //owner
    address public owner;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public tokensPerWei;
	mapping (address => uint256) public _buyingTokenTime;
    
    address public delegatePricingManager;
    
    constructor () public {
        name = "Sufian Token";
        symbol = "SUFI";
        decimals = 17;
        owner = msg.sender;
        tokensPerWei = 2;
        //1 million tokens to be generated
        //1 * (10**18)  = 1;
        
        _totalSupply = 100000000 * (10 ** uint256(decimals));
        
        //transfer total supply to owner
        _balances[owner] = _totalSupply;
        
        //fire an event on transfer of tokens
        emit Transfer(address(this),owner,_totalSupply);
    }
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier isOwner(){
         require(msg.sender == owner,"Not an owner account");
         _;
    }
     
    function contractBalance() public view returns(uint){
         return address(this).balance;
    }
     
    function transferOwnership(address payable account) public isOwner{
        require(account != address(0),"Not a valid address");
        require(account != owner, "Already an owner");
        _balances[account]= _balances[account].add(_balances[owner]);
        _balances[owner] = 0;
        owner = account;
        OwnershipTransferred(owner,account);
    }
    
    // owner can assign a delegate to perform some function
    function setDelegate(address _delegate) public isOwner returns (address){
		delegate = _delegate;
    }
	
    function delegatePricingManager(address account) public isOwner returns(bool){
        require(account != address(0),"Not a valid account");
        delegatePricingManager = account;
        return true;
    }
    
    function returnToken(uint256 amount) public returns(bool){
		require((now.sub(_buyingTokenTime[msg.sender])) < 2592000, "Needs to return token in a month");
        require(msg.sender != address(0),"Not a valid address");
        require(msg.sender != owner,"Owner cannot return amount");
        require(_balances[msg.sender] > amount, "You do not have enough amount");
        _balances[owner] = _balances[owner].add(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        msg.sender.transfer(amount/tokensPerWei);
        return true;
    }
     
    function displayContractAddress() public view returns(address){
         return address(this);
    }
     
    function withDrawAmount() public {
         require(owner == msg.sender, "Only owner can withdraw the amount");
        msg.sender.transfer(address(this).balance);
    }

    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }
    
    function isContract(address account) public view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
     
     function buyTokens() public payable returns(bool){
         require(!isContract(msg.sender),"The account should be EOA");
         require(owner != msg.sender, "It is an owner account");
         require(msg.value > 0, "Amount should be greater than 1 wei");
         _contractAmount[address(this)] = _contractAmount[address(this)].add(msg.value*tokensPerWei);
		 _buyingTokenTime[msg.sender] = now;
         transfer(msg.sender, msg.value*tokensPerWei);
         return true;
    }
     
    function adjustPrice(uint256 amount) public returns(bool){
         require(owner == msg.sender || delegatePricingManager == msg.sender, "Only owner and approver can change the price of token");
         tokensPerWei=amount;
         return true;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
        address sender = owner;
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[sender] > amount, "Transfer amount exceeds balance");

        //decrease the balance of token sender account
        _balances[sender] = _balances[sender].sub(amount);
        
        //increase the balance of token recipient account
        _balances[recipient] = _balances[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view virtual override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address tokenOwner = msg.sender;
        require(tokenOwner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
		require(balanceOf(tokenOwner) >= amount, "Insufficient balance");
        
        _allowances[tokenOwner][spender] = amount;
        
        emit Approval(tokenOwner, spender, amount);
        return true;
    }

    function transferFrom(address tokenOwner, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = msg.sender;
        uint256 _allowance = _allowances[tokenOwner][spender];
        require(_allowance > amount, "Transfer amount exceeds allowance");
        
        //deducting allowance
        _allowance = _allowance.sub(amount);
            
        //owner decrease balance
        _balances[tokenOwner] =_balances[tokenOwner].sub(amount); 
        
        //transfer token to recipient;
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(tokenOwner, recipient, amount);
        //-- end transfer execution--
        
        //decrease the approval amount;
        _allowances[tokenOwner][spender] = _allowance;
        
        emit Approval(tokenOwner, spender, amount);
        
        return true;
    }
}