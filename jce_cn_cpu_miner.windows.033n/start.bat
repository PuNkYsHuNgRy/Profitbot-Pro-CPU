@echo off

rem /!\ This is an EXAMPLE of miner start script, replace all EXAMPLE values with yours /!\

rem Pool address, can be a name or a dotted IP
rem Replace that EXAMPLE value with yours
set POOL=pool.monero.hashvault.pro

rem Pool port, can be standard or SSL.
rem If SSL, see note below.
rem Replace that EXAMPLE value with yours
set PORT=3333

rem If you use a SSL port, change to: set SSL=--ssl
rem Otherwise leave empty
set SSL=

rem Your wallet. Some pools let you add extra information at the end like .PAYMENTID or .FIXEDDIFF
rem no problem, that's supported.
rem Replace that EXAMPLE value with yours
rem This is the donation wallet.
set WALLET=43En6FLUc9EQPFjP21B73gLHBMPvUBV9LQxNA8ARsm7fLsMbybWeZgY6Dy1k77un6Z9BF8r7yxS6yTGCGdQhofYL6AvxwxZ

rem 'x' almost always works, some pools let you put a Worker name here. Rarely important.
set PASSWORD=x

rem  0 is "automatic", you can force one of:
rem  1 = Original Cryptonight
rem  2 = Original Cryptolight
rem  3 = Cryptonight V7 fork of April-2018
rem  4 = Cryptolight V7 fork of April-2018
rem  5 = Cryptonight-Heavy
rem  6 = Cryptolight-IPBC (obsolete)
rem  7 = Cryptonight-XTL fork of May-2018
rem  8 = Cryptonight-Alloy
rem  9 = Cryptonight-MKT
rem 10 = Cryptonight-Arto
rem 11 = Cryptonight-Masari/Fast
rem 12 = Cryptonight-Haven
rem 13 = Cryptonight-BitTube v2 of July-2018
rem 14 = Cryptolight-Red
rem 15 = Cryptonight V8 fork of October-2018
rem 16 = Pool-selected autoswitch
rem 17 = Cryptolight-Dark
rem 18 = Cryptonight-FreeHaven/Swap
rem 19 = Cryptolight-uPlexa
rem 20 = Cryptolight-Turtle v2
rem 21 = Cryptonight-Stellite v8

set FORK=0

rem Auto-Select 32 or 64 bits, don't change
if defined BITS goto :SkipBits
set BITS=64
if x%PROCESSOR_ARCHITECTURE%==xx86 set BITS=32
:SkipBits

rem All is good! Let's mine
@echo on
jce_cn_cpu_miner%BITS%.exe --auto --any --forever --keepalive --variation %FORK% --low -o %POOL%:%PORT% -u %WALLET% -p %PASSWORD% %SSL% %*
@pause
