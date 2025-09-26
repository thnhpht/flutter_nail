using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NailApi.Migrations
{
    /// <inheritdoc />
    public partial class AddTaxPercentToOrder : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "TaxPercent",
                table: "Orders",
                type: "decimal(18,2)",
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "Image",
                table: "Employees",
                type: "nvarchar(max)",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TaxPercent",
                table: "Orders");

            migrationBuilder.DropColumn(
                name: "Image",
                table: "Employees");
        }
    }
}
