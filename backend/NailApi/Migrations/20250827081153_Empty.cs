using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace NailApi.Migrations
{
    /// <inheritdoc />
    public partial class Empty : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DurationMin",
                table: "Service");

            migrationBuilder.DropColumn(
                name: "Description",
                table: "Category");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "DurationMin",
                table: "Service",
                type: "int",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<string>(
                name: "Description",
                table: "Category",
                type: "nvarchar(max)",
                nullable: true);
        }
    }
}
